library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity tristate_vector is
  generic (
    MODE : tristate_mode := PULL_DOWN;
    DATA_WIDTH : natural := 8
  );
  
  port (
    din : in std_logic_vector(DATA_WIDTH-1 downto 0);
    dout : out std_logic_vector(DATA_WIDTH-1 downto 0);
    en : in std_logic
  );

end entity tristate_vector;

architecture tristate_vector of tristate_vector is

begin
  dout <= din when en = '1' else 
          (others => 'Z') when en /= '1' and MODE = PULL_DOWN else
          (others => 'H') when en /= '1' and MODE = PULL_UP else
          (others => 'Z');
end architecture tristate_vector;
