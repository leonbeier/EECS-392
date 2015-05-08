library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;
use work.ycc_constants.all;

entity ycc_filter_tb is
end entity;

architecture test of ycc_filter_tb is
    
    signal clk: std_logic;
    signal y_t, cb_t, cr_t : natural;
    signal y_key, cb_key, cr_key : natural;
    signal result : std_logic;
    
    begin
        
        test_filter : ycc_filter port map(clk, y_t, cb_t, cr_t, y_key, cb_key, cr_key, result);
        
    process
        
        begin
          
          y_t <= 0;
          cb_t <= 100;
          cr_t <= 150;  
          y_key <= 0;
          cb_key <= 100;
          cr_key <= 150;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          cb_t <= 150;
          cr_t <= 100;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          cb_key <= 145;
          cr_key <= 102;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          cb_t <= 200;
          cr_key <= 120;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
        
        wait;
    end process;
        
end architecture test;

