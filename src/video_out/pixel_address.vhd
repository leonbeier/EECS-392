library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_out_constants.all;

entity pixel_address is
  port(
    pixel_row : in natural;
    pixel_col : in natural;
    
    ycc_read_addr : out natural;
    ycc_pixel_sel : out std_logic;
    bw_read_addr : out natural;
    bw_pixel_sel : out natural
  );
end entity;

architecture behavioral of pixel_address is
  --signal row, col : natural;
  signal read_addr_full : signed(31 downto 0);
begin
  
  --row <= pixel_row mod IMG_HEIGHT;
  --col <= pixel_col mod IMG_WIDTH;
  
  -- address if IMG_WIDTH * IMG_HEIGHT addresses existed
  read_addr_full <= to_signed(pixel_row * IMG_WIDTH + pixel_col, 32);
  
  -- each address holds data for 2 pixels, so ignore least significant bit
  ycc_read_addr <= to_integer(shift_right(read_addr_full, 1));
  ycc_pixel_sel <= read_addr_full(0);
  
  -- each address holds data for 8 pixels
	bw_read_addr <= to_integer(shift_right(read_addr_full, 3));
	bw_pixel_sel <= to_integer(unsigned(read_addr_full(2 downto 0)));
  
end architecture;


