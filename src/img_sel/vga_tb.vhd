library ieee;
use ieee.std_logic_1164.all;

entity vga_tb is
end entity;

architecture test of vga_tb is
  
component vga is
	port(
			clk, reset										             : in std_logic;
			pixel                            : in std_logic_vector(23 downto 0);
			
			pixel_clock_out				              : out std_logic;												
			pixel_row, pixel_col						       : out std_logic_vector(9 downto 0);
			horiz_sync_out, vert_sync_out    : out std_logic; 
			vga_blank                        : out std_logic;
			red, green, blue                 : out std_logic_vector(7 downto 0)
		);					    		
end component vga;

signal clk, reset										             : std_logic;
signal pixel                            : std_logic_vector(23 downto 0);
			
signal pixel_clock_out				              : std_logic;												
signal pixel_row, pixel_col						       : std_logic_vector(9 downto 0);
signal horiz_sync_out, vert_sync_out    : std_logic; 
signal vga_blank                        : std_logic;
signal red, green, blue                 : std_logic_vector(7 downto 0);

begin
  
    test_vga : vga port map(clk, reset, pixel, pixel_clock_out, pixel_row, pixel_col, horiz_sync_out, vert_sync_out, vga_blank, red, green, blue);
  
  process
  begin
    
    pixel <= (others => '0');
    
    clk <= '1';
    reset <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    reset <= '0';
  
    for i in 1 to 800000 loop
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
    
    wait for 5 ns;
    wait;
  
  end process;
  
end architecture;


