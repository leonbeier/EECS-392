library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;
use work.ycc_constants.all;

entity check_test is
end entity;

architecture test of check_test is
    
    signal y_t : bit;
    signal x_t : integer;
    
    begin
            
    process
        
        variable checkline : line;
        file checkfile : text open read_mode is "\\psf\Home\Documents\MATLAB\392\filter_check.txt";
        variable y : bit;
        
        variable inline : line;
        file infile : text open read_mode is "\\psf\Home\Documents\MATLAB\392\filter_input.txt";
        variable x : integer;
       
        
        begin
          
          wait for 5 ns;
            
            while not (endfile(checkfile)) loop
              
               readline(checkfile, checkline);
               read(checkline, y);
               
               readline(infile, inline);
               read(inline, x);
               
               y_t <= y;
               x_t <= x;
               
               wait for 5 ns;
            
            end loop;
        
        wait;
    end process;
        
end architecture test;
