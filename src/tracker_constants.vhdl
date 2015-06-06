library IEEE;
-- library IEEE_PROPOSED;
    
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
-- use IEEE_PROPOSED.fixed_pkg.all;

package tracker_constants is
  -- 50MHz clock with a default baud rate of 9600 (bits/second)
  constant CLOCK_FREQUENCY : integer := 50000000;
  constant DEFAULT_BAUD_RATE : natural := 25000000;   -- 9600
  
  -- Image constants
  constant IMAGE_WIDTH : natural := 640;
  constant IMAGE_HEIGHT : natural := 480;
  constant IMAGE_DEPTH : natural := 8;
  
  type uart_state is (TRIGGER, INIT, ACTIVE, STOP, HOLD);
  type i2c_state is (INIT, START, ADDRESS, DATA, STOP);
  type decoder_state is (VS_RESET, HS_RESET, READ);
  
  -- i2c constants
  constant I2C_ADDR_WIDTH : natural := 7;
  constant I2C_DATA_WIDTH : natural := 8;
  
  -- adv7180 constants
  constant ADV7180_LINES : natural := 720;
  
  -- ROM constants
  constant ROM_DATA_WIDTH : natural := 10;

  -- Integer constants
  type byte is natural range 0 to 255;
  
  -- fixed point math constants
  -- constant PI : ufixed(11 downto -20) := 3.14159265358979323846;
  -- dependent on the length of the sine lut in rom
  -- constant SINE_LUT_RESOLUTION : ufixed(11 downto -20) := 0.00153248422126331377;
  -- constant SINE_LUT_LENGTH : natural := 1024;
end package tracker_constants;
