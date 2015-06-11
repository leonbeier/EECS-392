library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity tristate is
  generic (
    MODE : tristate_mode := PULL_DOWN
  );
  
  port (
    din : in std_logic;
    dout : out std_logic;
    en : in std_logic
  );

end entity tristate;

architecture tristate of tristate is 
begin
  dout <= din when en = '1' else 
          'Z' when en /= '1' and MODE = PULL_DOWN else
          'H' when en /= '1' and MODE = PULL_UP else
          'Z';
end architecture tristate;
