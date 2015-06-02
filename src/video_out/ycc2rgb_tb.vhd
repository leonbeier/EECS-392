library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ycc2rgb_tb is
end entity;

architecture test of ycc2rgb_tb is
  
component ycc2rgb is
  port (
    clk : in std_logic;
    y, cb, cr : in std_logic_vector(7 downto 0);
    r, g, b : out std_logic_vector(7 downto 0)
  ); 
end component ycc2rgb;

signal clk, reset : std_logic;
signal y, cb, cr : std_logic_vector(7 downto 0);
signal r, g, b : std_logic_vector(7 downto 0);

begin
  
    test_convert : ycc2rgb port map(clk, y, cb, cr, r, g, b);
  
  process
  begin
    
    -- RED 81 90 240
    -- GREEN 145 54 34
    -- BLUE 41 240 110
    
    y <= std_logic_vector(to_signed(41, 8));
    cb <= std_logic_vector(to_signed(240, 8));
    cr <= std_logic_vector(to_signed(110, 8));
    
    clk <= '0';
    wait for 5 ns;
    clk <= '1';
    wait for 5 ns;
    
    wait;
  
  end process;
  
end architecture;




