library ieee;
use ieee.std_logic_1164.all;

entity video_out_tb is
end entity;

architecture test of video_out_tb is
  
component video_out is
	port(
			clk : in std_logic;
			reset : in std_logic;
			
			--VGA 
			red, green, blue : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk	: out std_logic
			
		);
end component video_out;

signal clk : std_logic;
signal reset : std_logic; 
signal red, green, blue : std_logic_vector(7 downto 0); 
signal h_sync, v_sync, blank, vga_clk	: std_logic;

begin
  
    test_video : video_out port map(clk, reset, red, green, blue, h_sync, v_sync, blank, vga_clk);
  
  process
  begin
    
    clk <= '1';
    reset <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    reset <= '0';
  
    for i in 1 to 2000000 loop
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
    
    wait for 5 ns;
    wait;
  
  end process;
  
end architecture;




