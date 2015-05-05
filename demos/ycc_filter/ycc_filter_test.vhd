library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use work.ycc_constants.all;

entity ycc_filter_tb is
end entity;

architecture test of ycc_filter_tb is
    
    signal y_t, cb_t, cr_t : natural;
    signal y_key, cb_key, cr_key : natural;
    signal result : std_logic;
    
    begin
        
        test_filter : ycc_filter port map(y_t, cb_t, cr_t, y_key, cb_key, cr_key, result);
        
    process
        
        variable inline : line;
        variable outline : line;
        file infile : text open read_mode is "filter_input.txt";
        file outfile : text open write_mode is "filter_output.txt";
        
        variable y : natural;
        variable cb : natural;
        variable cr : natural;
        
        variable rows : natural;
        variable cols : natural;
        
        begin
            
            y_key <= 0;
            cb_key <= 100;
            cr_key <= 210;
            
            readline(infile, inline);
            read(inline, rows);
          
            readline(infile, inline);
            read(inline, cols);
            
            write(outline, rows);
            writeline(outfile, outline);
           
            write(outline, cols);
            writeline(outfile, outline);
          
          wait for 5 ns;
            
            while not (endfile(infile)) loop
            
               readline(infile, inline);
               read(inline, y);
            
               readline(infile, inline);
               read(inline, cb);
            
               readline(infile, inline);
               read(inline, cr);
               
               y_t <= y;
               cb_t <= cb;
               cr_t <= cr;
              
               wait for 5 ns;
               
               write(outline, to_bit(result));
               writeline(outfile, outline);
            
            end loop;
        
        wait;
    end process;
        
end architecture test;