library IEEE;
    
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package tracker_constants is
  -- 50MHz clock with a default baud rate of 9600 (bits/second)
  constant CLOCK_FREQUENCY : integer := 50000000;
  constant DEFAULT_BAUD_RATE : natural := 25000000;   -- 9600
  
  -- math constants
  constant PI : integer := 3141592;
  constant PI_DIV : integer := 1000000;
  
  -- Image constants
  constant IMAGE_WIDTH : natural := 640;
  constant IMAGE_HEIGHT : natural := 480;
  constant IMAGE_DEPTH : natural := 8;
  
  type uart_state is (TRIGGER, INIT, ACTIVE, STOP, HOLD);
  type i2c_state is (INIT, START, ADDRESS, DATA, STOP);
  
  -- i2c constants
  constant I2C_ADDR_WIDTH : natural := 7;
  constant I2C_DATA_WIDTH : natural := 8;
  
  type image_buffer is array(IMAGE_HEIGHT-1 downto 0, IMAGE_WIDTH-1 downto 0) of std_logic_vector(IMAGE_DEPTH-1 downto 0);
    
end package tracker_constants;
