library IEEE;

use IEEE.std_logic_1164.all;

entity tristate is
  
  port (
    din : in std_logic;
    dout : out std_logic;
    en : in std_logic;
  );

end entity tristate;

architecture tristate of tristate is 
begin
  dout <= din when en = '1' else 'Z';
end architecture tristate;
