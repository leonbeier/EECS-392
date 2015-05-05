library IEEE;

use IEEE.std_logic_1164.all;

entity tristate is
  generic (
    DATA_WIDTH : natural := 8;
  );
  
  port (
    din : in std_logic_vector(DATA_WIDTH-1 downto 0);
    dout : out std_logic_vector(DATA_WIDTH-1 downto 0);
    en : in std_logic_vector(DATA_WIDTH-1 downto 0);
  );

end entity tristate;

architecture tristate of tristate is

begin
  dout <= din when en = '1' else (others => 'Z');
end architecture tristate;
