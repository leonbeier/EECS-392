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
    
    signal clk, reset: std_logic;
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
    pixel : in std_logic;
    
    center_row : out natural;
    center_col : out natural
  );
end component centroid;
    
    begin
        
        test_centroid : centroid
        generic map(ROWS, COLS)
        port map(clk, reset, pixel, center_row, center_col);
        
    process
        
        begin
          
          pixel <= '0';
          
          test <=   "10001" & 
                    "00000" & 
                    "00000" & 
                    "00000" & 
                    "10001" ;
                    
          wait for 5 ns;
          
          pixel <= '1';
          
        
        wait;
    end process;
        
end architecture test;



