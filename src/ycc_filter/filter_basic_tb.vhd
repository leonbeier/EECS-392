library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;
use work.ycc_constants.all;

entity filter_basic_tb is
end entity;

architecture test of filter_basic_tb is
    
    signal clk : std_logic;
    signal value, key, tolerance : natural;
    signal result : std_logic;
    
    begin
        
        filter : filter_basic port map(clk, value, key, tolerance, result);
        
    process
        begin
          
          value <= 500;
          key <= 500;
          tolerance <= 0;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          value <= 400;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          key <= 600;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
          tolerance <= 200;
          
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          
        
        wait;
    end process;
        
end architecture test;

