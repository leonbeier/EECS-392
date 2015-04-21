library IEEE;

use IEEE.std_logic_1164.all;

package tracker_constants is
  constant DEFAULT_BAUD_RATE : integer := 9600;
  
  type uart_state is (INIT, ACTIVE, STOP)
    
end package tracker_constants;

