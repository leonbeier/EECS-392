library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

package tracker_constants is
  -- 50MHz clock with a default baud rate of 9600 (bits/second)
  constant CLOCK_FREQUENCY : integer := 50000000;
  constant DEFAULT_BAUD_RATE : natural := 25000000;--9600;
  
  -- Image constants
  constant IMAGE_WIDTH : unsigned integer := 640;
  constant IMAGE_HEIGHT : unsigned integer := 480;
  
  type uart_state is (TRIGGER, INIT, ACTIVE, STOP, HOLD);
  type i2c_state is (INIT, START, ADDRESS, DATA, STOP, HOLD);
  
  -- i2c constants
  constant I2C_START : std_logic_vector(8 downto 0) := "00000001";
  constant I2C_ADDR_WIDTH : natural := 7;
  constant I2C_DATA_WIDTH : natural := 8;
  
  type image_buffer is array(IMAGE_HEIGHT-1 downto 0, IMAGE_WIDTH-1 downto 0) of std_logic_vector(IMAGE_DEPTH-1 downto 0);
    
end package tracker_constants;
