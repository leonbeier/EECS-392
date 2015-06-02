library ieee;
use ieee.std_logic_1164.all;

entity vga_tb is
end entity;

architecture test of vga_tb is
  
component VGA is
  generic(
    HORI_SCREENS : natural := 2;
    VERT_SCREENS : natural := 2
  );
	port(
			clk    : in std_logic;
			reset  : in std_logic;
			pixel  : in std_logic_vector(31 downto 0);
	
			--VGA 
			red, green, blue 					          : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk		: out std_logic;
			
			img_sel  : out std_logic_vector(1 downto 0);
			row      : out natural;
			col      : out natural
		);
end component VGA; 

signal clk, reset : std_logic;
signal pixel : std_logic_vector(31 downto 0);

signal red, green, blue : std_logic_vector(7 downto 0);
signal h_sync, v_sync, blank, vga_clk : std_logic;
signal img_sel : std_logic_vector(1 downto 0);
signal row, col : natural;

begin
  
    test_mod : vga port map(clk, reset, pixel, red, green, blue, h_sync, v_sync, blank, vga_clk, img_sel, row, col);
  
  process
  begin
    
    pixel <= (others => '0');
    
    clk <= '1';
    reset <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    reset <= '0';
  
    for i in 1 to 10 loop
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
    
    wait for 5 ns;
    wait;
  
  end process;
  
end architecture;


