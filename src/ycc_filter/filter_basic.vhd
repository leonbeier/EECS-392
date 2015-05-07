library ieee;
use ieee.std_logic_1164.all;
use work.ycc_constants.all;

entity filter_basic is
  port(
    clk : in std_logic;
    value : in integer;
    key : in integer;
    tolerance : in integer;
    
    result : out std_logic
  );
end entity filter_basic;

architecture behavior of filter_basic is

begin
    
  process(clk)
    variable low_bound, up_bound : integer;
    variable res : std_logic := '0';
  begin
    low_bound := key - tolerance;
    up_bound := key + tolerance;    
    
    if (falling_edge(clk)) then
      if (value >= low_bound and value <= up_bound) then
        result <= '1';
      else
        result <= '0';
      end if;
    end if;
    
  end process;

end architecture behavior;
