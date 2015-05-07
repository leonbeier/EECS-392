library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;
use work.ycc_constants.all;

entity ycc_filter_test_io is
  port (
    valid : out bit;
    not_valid : out bit;
    
    bit_true : out bit;
    fail_true : out bit
  );
end entity;

architecture test of ycc_filter_test_io is
    
    signal clk, reset: std_logic;
    signal y_t, cb_t, cr_t : natural;
    signal y_key, cb_key, cr_key : natural;
    signal result : std_logic;
    signal valid_s, bit_true_s : bit;
    signal not_valid_s, fail_true_s : bit;
    signal check, fail: bit;
    
    begin
        
        test_filter : ycc_filter port map(clk, y_t, cb_t, cr_t, y_key, cb_key, cr_key, result);
        
    process
        
        variable inline : line;
        variable checkline : line;
        variable failline : line;
        variable outline : line;
        file infile : text open read_mode is "\\psf\Home\Documents\MATLAB\392\filter_input.txt";
        file checkfile : text open read_mode is "\\psf\Home\Documents\MATLAB\392\filter_check.txt";
        file failfile : text open read_mode is "\\psf\Home\Documents\MATLAB\392\filter_fail.txt";
        file outfile : text open write_mode is "\\psf\Home\Documents\MATLAB\392\filter_output.txt";
        
        variable y : natural;
        variable cb : natural;
        variable cr : natural;
        
        variable blue_key : natural;
        variable red_key : natural;
        
        variable rows : natural;
        variable cols : natural;
        
        variable check_v : bit; 
        variable fail_v : bit;
        
        begin
            clk <= '1';
            reset <= '1';
            wait for 5 ns;
            reset <= '0';
            clk <= '0';
               
            readline(infile, inline);
            read(inline, blue_key);
            
            readline(infile, inline);
            read(inline, red_key);
            
            y_key <= 0;
            cb_key <= blue_key;
            cr_key <= red_key;
            
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
              
               clk <= '1';
            
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
               clk <= '0';
               
               readline(checkfile, checkline);
               read(checkline, check_v);
               check <= check_v;
               
               readline(failfile, failline);
               read(failline, fail_v);
               fail <= fail_v;
               
               wait for 5 ns;
               
               write(outline, to_bit(result));
               writeline(outfile, outline);
            
            end loop;
        
        wait;
    end process;
    
    valid_s <= check xnor to_bit(result);
    not_valid_s <= fail xnor to_bit(result);
    
    process(clk, reset)
    begin
      if reset = '1' then
        bit_true_s <= '1';
        fail_true_s <= '1';
      elsif falling_edge(clk) then
        bit_true_s <= bit_true_s and valid_s;
        fail_true_s <= fail_true_s and not_valid_s;
      end if;
    end process;
    
    valid <= valid_s;
    not_valid <= not_valid_s;
    
    bit_true <= bit_true_s;
    fail_true <= fail_true_s;
        
end architecture test;