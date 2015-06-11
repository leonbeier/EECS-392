library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity i2c is
  
  generic (
    FREQUENCY : natural := 12_500_000 --10,000
  );
  
  port (
    -- clocks
    clock_50 : in std_logic;
    reset : in std_logic;
    error : out std_logic;
    
    -- i2c communications
    sda : inout std_logic;
    scl : inout std_logic;
    data_clk : in std_logic;
    data_addr : in std_logic_vector(I2C_ADDR_WIDTH-1 downto 0);
    data_in : in std_logic_vector(I2C_DATA_WIDTH-1 downto 0);
    write_en, read_en : in std_logic; -- writing takes prescedence over reading
    available : out std_logic;
    
    -- fifo control
    write : in std_logic;
    odata : out std_logic_vector(7 downto 0);
    idata : in std_logic_vector(7 downto 0);

    -- TESTING
    state : out std_logic_vector(3 downto 0)
  );
end entity i2c;

architecture i2c of i2c is 

  component tristate is
  
  generic (
    MODE : tristate_mode := PULL_DOWN
  );
  
  port (
    din : in std_logic;
    dout : out std_logic;
    en : in std_logic
  );

  end component tristate;

  -- i2c controller
  signal i2c_s : i2c_state;
  
  -- fifos
  signal tx_read, tx_empty : std_logic;
  signal tx_data : std_logic_vector(7 downto 0);
  signal rx_write, rx_full : std_logic;
  signal rx_data : std_logic_vector(7 downto 0);
  
  -- temps
  signal i2c_period_count : natural;
  signal sda_write : std_logic;
  signal sda_enable : std_logic;
  signal scl_write : std_logic;
  signal scl_enable : std_logic;

  signal clock_ct : natural;
  signal data_ct : natural;
begin
  
  i2c_period_count <= 50_000_000 / FREQUENCY;
  sda_map: tristate generic map(MODE => PULL_UP)
                    port map(din => sda_write, dout => sda, en => sda_enable);
  scl_map: tristate generic map(MODE => PULL_DOWN)
                    port map(din => scl_write, dout => scl, en => scl_enable);

  state <= "0000" when (i2c_s = INIT) else
           "0001" when (i2c_s = START) else
           "0010" when (i2c_s = ADDRESS) else
           "0011" when (i2c_s = DATA) else
           "0100" when (i2c_s = STOP) else
           "0101";
  
  -- master device drives scl
--  i2c_manager: process(clock_50, reset, rx_write, rx_full, rx_data, tx_read, tx_empty, tx_data)
  i2c_manager: process(clock_50, reset) 
    variable data_buffer : std_logic_vector(I2C_DATA_WIDTH-1 downto 0);           -- buffer the address
    variable data_addr_buffer : std_logic_vector(I2C_ADDR_WIDTH-1 downto 0);
    variable writing, reading : std_logic;
    variable clock_count : natural := 0; 
    variable data_count : natural := 0;
    variable active : std_logic := '0';
    variable er : std_logic := '0';
  begin
    if(reset = '0') then
      -- active low reset
      reading := '0';
      writing := '0';
      error <= '0';
      i2c_s <= INIT;
    elsif(rising_edge(clock_50)) then
      clock_ct <= clock_count;
      data_ct <= data_count;
      case(i2c_s) is
        when INIT =>
          -- wait until the user sets a mode
          --  modes: write, read where write has the higher priority
          clock_count := 0;
          clock_ct <= 0;
          sda_enable <= '0';
          scl_enable <= '1';
          scl_write <= '1';
          data_buffer := data_in;
          data_addr_buffer := data_addr;
          clock_count := 0;
          data_count := 0;
          available <= '1';
          if(write_en = '1') then
            sda_enable <= '1';
            writing := '1';
            reading := '0';
            available <= '0';
            i2c_s <= START;
          elsif(read_en = '1') then
            sda_enable <= '0';
            reading := '1';
            writing := '0';
            available <= '0';
            i2c_s <= START;
          else
            reading := '0';
            writing := '0';
          end if;
------------------------------------------------------------------------
        when START =>
          -- send out the start signal
          if(clock_count = 0) then
            if(scl /= '0') then
              sda_enable <= '1';
              sda_write <= '0';
            else
              i2c_s <= INIT; 
            end if;
            clock_count := clock_count + 1;
          elsif(clock_count < i2c_period_count/4) then
            clock_count := clock_count + 1;
          elsif(clock_count = i2c_period_count/4) then
            scl_write <= '0';
            clock_count := clock_count + 1;
          elsif(clock_count < i2c_period_count /2) then
            clock_count := clock_count + 1;
          else
            clock_count := 0;
            i2c_s <= ADDRESS;
          end if;
------------------------------------------------------------------------
        when ADDRESS =>
          -- inactive if write or read were set but not data latched
          --  into the data buffer
          --  writing or reading data
          if(data_count <= I2C_ADDR_WIDTH+1) then
            -- move through the data buffer and update pulse
            if(clock_count < i2c_period_count/4) then
              scl_write <= '0';
              clock_count := clock_count + 1;
            elsif(clock_count < i2c_period_count/2) then
              scl_write <= '0';
              if(data_count < I2C_ADDR_WIDTH and scl = '0') then
                -- send out the address bits msb first
                sda_enable <= '1';
                sda_write <= data_addr_buffer(I2C_ADDR_WIDTH-1-data_count);
              elsif(data_count = I2C_ADDR_WIDTH) then
                -- send out the r/w bit
                sda_enable <= '1';
                if(writing = '1') then
                  sda_write <= '0';
                elsif(reading = '1') then
                  sda_write <= '1';
                else
                  error <= '1';
                  i2c_s <= INIT;
                end if;
              elsif(data_count = I2C_ADDR_WIDTH+1) then
                -- read the acknowledgement bit
                sda_enable <= '0'; 
              end if;
              clock_count := clock_count + 1;
            elsif(clock_count = i2c_period_count/2) then
              scl_write <= '1';
              if(data_count = I2C_ADDR_WIDTH+1) then
                if(sda = '1') then
                  error <= '1';
                  i2c_s <= INIT;
                end if;
              end if;
              clock_count := clock_count + 1;
            elsif(clock_count < i2c_period_count-1) then
              scl_write <= '1';
              clock_count := clock_count + 1;
            elsif(clock_count = i2c_period_count-1) then
              data_count := data_count + 1;
              clock_count := 0;
            end if;
          else
            data_count := 0;
            clock_count := 0;
            i2c_s <= DATA;
          end if;
------------------------------------------------------------------------
        when DATA =>
          if(data_count <= I2C_ADDR_WIDTH+1) then
            -- move through the data buffer and update pulse
            if(clock_count = 0) then
              scl_write <= '0';
              clock_count := clock_count + 1;
            elsif(clock_count < i2c_period_count/2) then
              scl_write <= '0';
              clock_count := clock_count + 1;
            elsif(clock_count = i2c_period_count/2 and data_count <= I2C_DATA_WIDTH) then
              scl_write <= '1';
              if(writing ='1') then
                -- take the data line for writing
                sda_enable <= '1';
                sda_write <= data_buffer(I2C_DATA_WIDTH-1-data_count);
              elsif(reading ='1') then
                -- give the data line to the slave
                sda_enable <= '0';
                data_buffer(I2C_DATA_WIDTH-1-data_count) := sda;
              else
                -- should not be writing or reading
                i2c_s <= INIT;
              end if;
              clock_count := clock_count + 1;
            elsif(clock_count = i2c_period_count/2 and data_count = I2C_DATA_WIDTH+1) then
              scl_write <= '1';
              sda_enable <= '0';
              if(sda = '1') then
                error <= '1';
                i2c_s <= INIT;
              end if;
              clock_count := clock_count +1;
            elsif(clock_count < i2c_period_count-1) then
              scl_write <= '1';
              clock_count := clock_count + 1;
            elsif(clock_count = i2c_period_count-1) then
              data_count := data_count + 1;
              clock_count := 0;
            end if;
          else
            i2c_s <= STOP;
            clock_count := 0;
          end if;
------------------------------------------------------------------------
        when STOP =>
          if(clock_count < i2c_period_count/2) then
            if(writing = '0' and reading = '1') then
              odata <= data_buffer;
            end if; 
            scl_write <= '0';
            clock_count := clock_count +1;
          elsif(clock_count = i2c_period_count/2) then
            sda_enable <= '1';
            sda_write <= '0';
            scl_write <= '1';
            clock_count := clock_count +1;
          elsif(clock_count < (3*i2c_period_count)/4) then
            sda_write <= '1';
            clock_count := clock_count +1;
          elsif(clock_count < i2c_period_count) then
            clock_count := clock_count +1;
          elsif(clock_count = i2c_period_count) then
            clock_count := 0;
            data_count := 0;
            error <= '0';
            i2c_s <= INIT;
          end if;
        when OTHERS =>
          i2c_s <= INIT;
      end case;
    end if;
  end process i2c_manager;

end architecture i2c;
