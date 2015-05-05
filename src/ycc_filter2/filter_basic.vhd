library ieee;
use ieee.std_logic_1164.all;
use work.ycc_constants.all;

entity filter_basic is
  port(
    value : in integer;
    key : in integer;
    tolerance : in integer;
    
    result : out std_logic
  );
end entity filter_basic;

architecture behavior of filter_basic is

begin
    
  process(value, key, tolerance)
    variable low_bound, up_bound : integer;
  begin
    low_bound := key - tolerance;
    up_bound := key + tolerance;
    
    if (value >= low_bound and value <= up_bound) then
      result <= '1';
    else
      result <= '0';
    end if;
    
  end process;

end architecture behavior;
