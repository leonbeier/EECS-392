library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity i2c is
  
  generic (
    FREQUENCY : natural := 100000;
  );
  
  port (
    -- clocks
    clock_50 : in std_logic;
    reset : in std_logic;
    
    -- i2c communications
    sda : inout std_logic;
    scl : inout std_logic;
    data_clk : in std_logic;
    data_addr : in std_logic_vector(I2C_DATA_WIDTH-1 downto 0);
    data : in std_logic_vector(I2C_DATA_WIDTH-1 downto 0);
    write_en, read_en : in std_logic; -- writing takes prescedence over reading
    available : out std_logic;
    
    -- fifo control
    write : in std_logic;
    odata : out std_logic_vector(7 downto 0);
    idata : in std_logic_vector(7 downto 0);
  );
end entity i2c;

architecture i2c of i2c is 
  -- i2c controller
  signal i2c_s : i2c_state;
  
  -- fifos
  signal tx_write, tx_full : std_logic;
  signal tx_data : std_logic_vector(7 downto 0);
  signal rx_read, rx_empty : std_logic;
  signal rx_data : std_logic_vector(7 downto 0);
  
  -- temps
  signal i2c_period_count : natural;
  signal sda_write : std_logic;
  signal sda_enable : std_logic;
  signal scl_write : std_logic;
  signal scl_enable : std_logic;
begin
  
  i2c_period_count <= 50_000_000 / FREQUENCY;
  sda_map: tristate port map(din => sda_write, dout => sda, den => sda_enable)
  scl_map: tristate port map(din => scl_write, dout => scl, den => scl_enable)
  
  -- master device drives scl
  i2c_manager: process(clock_50, reset, rx_write, rx_empty, rx_data, tx_read, tx_full, tx_data)
    variable data_buffer : std_logic_vector(I2C_DATA_WIDTH-1 downto 0);           -- buffer the address
    variable data_addr_buffer : std_logic_vector(I2C_DATA_WIDTH-1 downto 0:
    variable writing, reading : std_logic;
    variable clock_count : natural := 0;
    variable data_count : natural := 0;
    variable active : std_logic := '0';
  begin
    if(rising_edge(clock_50)) then
      case(i2c_s)
        when INIT =>
          -- wait until the user sets a mode
          --  modes: write, read where write has the higher priority
          counter := 0;
          if(write_en = '1') then
            sda_enable <= '1';
            writing := '1';
            reading := '0';
            available <= '0';
            i2c_s <= START;
          elsif(read_en = '1') then
            sda_enable <= '0';
            reading := '0';
            writing := '1';
            available <= '0';
            i2c_s <= START;
          else
            reading := 0;
            writing := 0;
            available <= '1';
          end if;
        when START =>
          -- send out the start byte
          if(data_count /= I2C_START'size) then
            if(clock_count = 0) then
              sda_write <= I2C_START(data_count);
            if(clock_count = i2c_period_count/4) then
              scl_write <= '1';
            elsif(clock_count = (3*i2c_period_count/4)) then
              scl_write <= '0';
            elsif(clock_count > i2c_period_count) then
              data_count := data_count + 1;
              clock_count := 0;
            end if;
            
            -- increment clock counter
            if(clock_count <= i2c_period_count) then
              clock_count := clock_count + 1;
            end if;
          else
            i2c_s <= ACTIVE;
          end if;
        when ACTIVE =>
          -- send data at the change of the clock signal until
          -- disabled
          if(active = '0') then
            -- inactive if write or read were set but not data latched
            --  into the data buffer
            if(writing = '1' or reading = '1') then 
              -- wait for new data from the user line
              if(rising_edge(data_clk)) then
                -- latch data into the data buffer
                data_buffer := data;
                data_addr_buffer := data_addr;
                clock_count := 0;
                data_count := 0;
                active := '1';
              end if;
            else
              -- stop waiting for new data from the user line
              i2c_s <= INIT;
            end if;
          elsif(active = '1') then
            -- writing or reading data
            if(data_count /= I2C_DATA_WIDTH) then
              if(writing) then
                -- move through the data buffer and update pulse
                if(clock_count = 0) then
                  sda_write <= data_buffer(data_count);
                elsif(clock_count = i2c_period_count/4) then
                  scl_write <= '1';
                elsif(clock_count = (3*i2c_period_count/4)) then
                  scl_write <= '0';
                elsif(clock_count > i2c_period_count) then
                  data_count := data_count + 1;
                  clock_count := 0;
                end if;
                
                -- increment the clock count
                if(clock_count <= i2c_period_count) then
                  clock_count := clock_count + 1;
                end if;
              elsif(reading) then
                -- move through the data buffer while reading pulse
                -- wait for the clock to change
                if(falling_edge(scl)) then
                  data_buffer(data_count) <= sda;
                  data_count := data_count + 1;
                end if;
              end if;
            else
              i2c_s <= STOP;
            end if;
          end if;
        when STOP =>
          if(writing) then
            if(clock_count > i2c_period_count) then
              if(sda = '0') then
                -- turn on the error bit
              end if;
            end if;
            
            if(clock_count <= i2c_period_count) then
              clock_count := clock_count + 1;
            end if;
          elsif(reading) then
            if(falling_edge(scl)) then
              if(sda = '0') then
                -- load data into the fifo
              end if;
            end if;
          end if;
        when HOLD =>
          if(clock_count = i2c_period_count) then
            active <= '0';
            i2c_s <= ACTIVE;
          end if;
          
          if(clock_count < i2c_period_count) then
            clock_count := clock_count + 1;
          end if;
    end if;
  end process i2c_manager;

end architecture i2c;
