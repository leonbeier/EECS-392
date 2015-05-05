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
    data_addr : in std_logic_vector(I2C_ADDR_WIDTH-1 downto 0);
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
          sda_enable <= '0';
          scl_enable <= '1';
          data_buffer := data;
          data_addr_buffer := data_addr;
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
            i2c_s <= START;
          else
            reading := 0;
            writing := 0;
          end if;
          
          if(rising_edge(data_clk)) then
            available <= '0';
            i2c_s <= START;
          else
            available <= '1';
          end if;
        when START =>
          -- send out the start signal
          if(scl /= '0') then
            sda_enable <= '1';
            sda_write <= '0';
            i2c_s <= ACTIVATION;
          else
            i2c_s <= INIT; 
          end if;
        when ADDRESS =>
          -- inactive if write or read were set but not data latched
          --  into the data buffer
          --  writing or reading data
          if(data_count <= I2C_ADDR_WIDTH+1) then
            -- move through the data buffer and update pulse
            if(clock_count = 0) then
              if(data_count < I2C_ADDR_WIDTH) then
                -- send out the address bits msb first
                sda_enable <= '1';
                sda_write <= data_addr_buffer(I2C_ADDR_WIDTH-1-data_count);
              elsif(data_count = I2C_ADDR_WIDTH) then
                -- send out the r/w bit
                sda_enable <= '1';
                if(writing) then
                  sda_write <= '1';
                elsif(reading) then
                  sda_write <= '0';
                else
                  i2c_s <= INIT;
                end if;
              elsif(data_count = I2C_ADDR_WIDTH+1) then
                -- read the acknowledgement bit
                sda_enable <= '0'; 
              end if;
            elsif(clock_count = i2c_period_count/4) then
              scl_write <= '0';
            elsif(data_count = I2C_ADDR_WIDTH+1 and clock_count = i2c_period_count/2) then
              sdsa_enable <= '0';
              if(sda /= '0') then
                -- TODO: Create an error signal 
                -- Acknownledgement Error
                i2c_s <= INIT;
              end if;
            elsif(clock_count = (3*i2c_period_count/4)) then
              scl_write <= '1';
            elsif(clock_count > i2c_period_count) then
              data_count := data_count + 1;
              clock_count := 0;
            end if;
            
            -- increment the clock count
            if(clock_count < i2c_period_count) then
              clock_count := clock_count + 1;
            end if;
          else
            data_count := 0;
            i2c_s <= DATA;
          end if;
        when DATA =>
          if(data_count <= I2C_ADDR_WIDTH+1) then
            -- move through the data buffer and update pulse
            if(clock_count = 0) then
              if(data_count < I2C_DATA_WIDTH) then
                -- send out the address bits msb first
                if(writing) then
                  -- take the data line for writing
                  sda_enable <= '1';
                  sda_write <= data_buffer(I2C_DATA_WIDTH-1-data_count);
                elsif(reading) then
                  -- give the data line to the slave
                  sda_enable <= '0';
                else
                  -- should not be writing or reading
                  i2c_s <= INIT;
                end if;
              elsif(data_count = I2C_DATA_WIDTH) then
                -- read the acknowledgement bit
                sda_enable <= '0';
              end if;
            elsif(clock_count = i2c_period_count/4) then
              scl_write <= '0';
            elsif(clock_count = i2c_period_count/2) then
              if(writing = '0' and reading = '1' and data_count < I2C_DATA_WIDTH) then 
                data_buffer(I2C_DATA_WIDTH-1-data_count) = sda;
              end if;
            elsif(clock_count = (3*i2c_period_count/4)) then
              scl_write <= '1';
            elsif(clock_count > i2c_period_count) then
              data_count := data_count + 1;
              clock_count := 0;
            end if;
            
            -- increment the clock count
            if(clock_count < i2c_period_count) then
              clock_count := clock_count + 1;
            end if;
          else
            i2c_s <= STOP;
          end if;
        when STOP =>
          if(clock_count = 0) then
            if(writing = '0' and reading = '1') then
              -- load data into buffer if reading
            end if; 
            sda_enable = '1';
            scl_write <= '0';
          elsif(clock_count = i2c_period_count/4) then
            scl_write <= '1';
          elsif(clock_count = i2c_period_count/2) then
            sda_write <= '0';
          elsif(clock_count = (3*i2c_period_count)/4) then
            sda_write <= '1';
          elsif(clock_count = i2c_period_count) then
            clock_count = 0;
            i2c_s <= INIT;
          end if;
    end if;
  end process i2c_manager;

end architecture i2c;
