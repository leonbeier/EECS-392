library IEEE;
use IEEE.numeric_std.all;
use IEEE.std_logic_1164.all;

package tracker_constants is
  -- 50MHz clock with a default baud rate of 9600 (bits/second)
  constant CLOCK_FREQUENCY : integer := 50000000;
  constant DEFAULT_BAUD_RATE : natural := 25000000;--9600;
  
  type uart_state is (TRIGGER, INIT, ACTIVE, STOP, HOLD);
    
end package tracker_constants;
