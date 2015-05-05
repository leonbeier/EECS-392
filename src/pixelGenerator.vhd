library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.TankGameConstants.all;

entity pixelGenerator is
	port(
			clk, ROM_clk, rst_n, video_on, eof 				: in std_logic;
			pixel_row, pixel_column						    : in std_logic_vector(9 downto 0);
			tanks : in Sprites;
			bullets : in Sprites;
			red_out, green_out, blue_out					: out std_logic_vector(9 downto 0)
		);
end entity pixelGenerator;

architecture behavioral of pixelGenerator is

constant color_red 	 	 : std_logic_vector(2 downto 0) := "000";
constant color_green	 : std_logic_vector(2 downto 0) := "001";
constant color_blue 	 : std_logic_vector(2 downto 0) := "010";
constant color_yellow 	 : std_logic_vector(2 downto 0) := "011";
constant color_magenta 	 : std_logic_vector(2 downto 0) := "100";
constant color_cyan 	 : std_logic_vector(2 downto 0) := "101";
constant color_black 	 : std_logic_vector(2 downto 0) := "110";
constant color_white	 : std_logic_vector(2 downto 0) := "111";
	
component colorROM is
	port
	(
		address		: in std_logic_vector (2 downto 0);
		clock		: in std_logic  := '1';
		q			: out std_logic_vector (29 downto 0)
	);
end component colorROM;

signal colorAddress : std_logic_vector (2 downto 0);
signal color        : std_logic_vector (29 downto 0);

signal pixel_row_int, pixel_column_int : natural;

begin

--------------------------------------------------------------------------------------------
	
	red_out <= color(29 downto 20);
	green_out <= color(19 downto 10);
	blue_out <= color(9 downto 0);

	pixel_row_int <= to_integer(unsigned(pixel_row));
	pixel_column_int <= to_integer(unsigned(pixel_column));
	
--------------------------------------------------------------------------------------------	
	
	colors : colorROM
		port map(colorAddress, ROM_clk, color);

--------------------------------------------------------------------------------------------	

	pixelDraw : process(clk, rst_n) is
	
	begin
			
		if (rising_edge(clk)) then
			
			-- Pixel Color Update
			if(tanks(0).visible = '1' and tanks(0).tlx <= pixel_column_int and tanks(0).tlx + tanks(0).w >= pixel_column_int and tanks(0).tly <= pixel_row_int and tanks(0).tly + tanks(0).h >= pixel_row_int) then
				colorAddress <= tanks(0).color;
			elsif(tanks(1).visible = '1' and tanks(1).tlx <= pixel_column_int and tanks(1).tlx + tanks(1).w >= pixel_column_int and tanks(1).tly <= pixel_row_int and tanks(1).tly + tanks(1).h >= pixel_row_int) then
				colorAddress <= tanks(1).color;
			elsif(bullets(0).visible = '1' and bullets(0).tlx <= pixel_column_int and bullets(0).tlx + bullets(0).w >= pixel_column_int and bullets(0).tly <= pixel_row_int and bullets(0).tly + bullets(0).h >= pixel_row_int) then
			 	colorAddress <= bullets(0).color;
			elsif(bullets(1).visible = '1' and bullets(1).tlx <= pixel_column_int and bullets(1).tlx + bullets(1).w >= pixel_column_int and bullets(1).tly <= pixel_row_int and bullets(1).tly + bullets(1).h >= pixel_row_int) then
				colorAddress <= bullets(1).color;
			else
				colorAddress <= color_cyan;
			end if;
			
		end if;
		
	end process pixelDraw;	

--------------------------------------------------------------------------------------------
	
end architecture behavioral;		