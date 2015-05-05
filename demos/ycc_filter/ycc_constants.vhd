library ieee;
use ieee.std_logic_1164.all;

package ycc_constants is

constant Y_TOL : natural := 0;
constant CB_TOL : natural := 5;
constant CR_TOL : natural := 5;

component filter_basic is
  port(
    value : in integer;
    key : in integer;
    tolerance : in integer;
    result : out std_logic
  );
end component filter_basic;

component ycc_filter is
  port(
    y : in natural;
    cb : in natural;
    cr : in natural;
    
    y_key : in natural;
    cb_key : in natural;
    cr_key : in natural;
    
    result : out std_logic
  );
end component ycc_filter;
  
end package; 