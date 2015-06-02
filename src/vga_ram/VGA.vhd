library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA is
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
end entity VGA;

architecture structural of VGA is
  
  constant FULL_WIDTH : natural := 640;
  constant FULL_HEIGHT : natural := 480;
  constant WIDTH : natural := FULL_WIDTH / HORI_SCREENS;
  constant HEIGHT : natural := FULL_HEIGHT / VERT_SCREENS;

component VGA_SYNC is
	port(
			clock_50Mhz, reset										     : in std_logic;
			horiz_sync_out, vert_sync_out, 
			video_on, pixel_clock, eof						 : out std_logic;												
			pixel_row, pixel_col						       : out std_logic_vector(9 downto 0)
		);
end component VGA_SYNC;

--Signals for VGA sync
signal pixel_row 			    : std_logic_vector(9 downto 0);
signal pixel_col        : std_logic_vector(9 downto 0);
signal video_on_int					: std_logic;
signal VGA_clk_int						: std_logic;
signal eof												: std_logic;

signal pixel_row_int : natural;
signal pixel_col_int : natural;

begin
  
  row <= pixel_row_int mod HEIGHT;
  col <= pixel_col_int mod WIDTH;
  
  red <= pixel(23 downto 16);
  green <= pixel(15 downto 8);
  blue <= pixel(7 downto 0);
  
  pixel_row_int <= to_integer(unsigned(pixel_row));
  pixel_col_int <= to_integer(unsigned(pixel_col));
  
  process(clk)
  begin
    if (pixel_col_int < 320) then
      img_sel(0) <= '0';
    else
      img_sel(0) <= '1';
    end if;
    
    if (pixel_row_int < 240) then
      img_sel(1) <= '0';
    else
      img_sel(1) <= '1';
    end if;
  end process;
  
--This section should not be modified in your design.  This section handles the VGA timing signals
--and outputs the current row and column.  You will need to redesign the pixelGenerator to choose
--the color value to output based on the current position.

	videoSync : VGA_SYNC
		port map(clk, reset, h_sync, v_sync, video_on_int, VGA_clk_int, eof, pixel_row, pixel_col);

	blank <= video_on_int;

	vga_clk <= VGA_clk_int;
	
	end architecture structural;

