library ieee;
use ieee.std_logic_1164.all;
use work.ycc_constants.all;

entity ycc_filter is
  port(
    clk : in std_logic;
    
    y : in natural;
    cb : in natural;
    cr : in natural;
    
    y_key : in natural;
    cb_key : in natural;
    cr_key : in natural;
    
    result : out std_logic
  );
end entity ycc_filter;

architecture behavior of ycc_filter is
  signal cb_res, cr_res : std_logic;
begin
  
  cb_filter : filter_basic port map(clk => clk, value => cb, key => cb_key, tolerance => CB_TOL, result => cb_res);
  cr_filter : filter_basic port map(clk => clk, value => cr, key => cr_key, tolerance => CR_TOL, result => cr_res);
  
  result <= cb_res and cr_res;
  
  --process(clk)
  --begin
    --if (falling_edge(clk)) then
      
    --end if;
  --end process;
  
end architecture behavior;
