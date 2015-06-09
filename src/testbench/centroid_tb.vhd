library ieee;
use ieee.std_logic_1164.all;
use std.textio.all;
use ieee.numeric_std.all;

entity centroid_tb is
end entity;

architecture test of centroid_tb is
    
    constant ROWS : natural := 5;
    constant COLS : natural := 5;
    constant N : natural := ROWS * COLS;
    
    signal clk, reset : std_logic;
    signal enable : std_logic;
    signal pixel : std_logic;
    signal center_row, center_col : natural;
    signal test : std_logic_vector (1 to N);
    
component centroid is
  generic(
    ROWS : natural := 240;
    COLS : natural := 320
  ); 
  port(
    clk : in std_logic;
    reset : in std_logic;
    enable : in std_logic;
    pixel : in std_logic;
    
    center_row : out natural;
    center_col : out natural
  );
end component centroid;
    
    begin
        
        test_centroid : centroid
        generic map(ROWS, COLS)
        port map(clk, reset, enable, pixel, center_row, center_col);
        
    process
        
        begin
          test <=   "00000" & 
                    "00111" & 
                    "00101" & 
                    "00111" & 
                    "00000" ;
                    
          pixel <= '0';
          
          enable <= '1';
          reset <= '0';
          clk <= '1';
          wait for 5 ns;
          clk <= '0';
          wait for 5 ns;
          reset <= '1';
          
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          test <=   "11011" & 
                    "10101" & 
                    "00000" & 
                    "10101" & 
                    "11011" ;
                    
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          test <=   "10001" & 
                    "00000" & 
                    "00000" & 
                    "00000" & 
                    "10001" ;
                    
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          test <=   "11100" & 
                    "11100" & 
                    "11100" & 
                    "00000" & 
                    "00000" ;
                    
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          test <=   "10100" & 
                    "10100" & 
                    "10100" & 
                    "10100" & 
                    "10100" ;
                    
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          test <=   "00000" & 
                    "00000" & 
                    "11111" & 
                    "11111" & 
                    "00000" ;
                    
          for i in 1 to N loop
            clk <= '1';
            pixel <= test(i);
            wait for 5 ns;
            clk <= '0';
            wait for 5 ns;
          end loop;
          
          wait for 10 ns;
          
        wait;
    end process;
        
end architecture test;



