library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;


entity ycbcr2hsv is
  
  generic (
    Y_WIDTH : natural := 4;
    CB_WIDTH : natural := 2;
    CR_WIDTH : natural := 2;
    RGB_BASE_WIDTH : natural := 8
  );
  
  port (
    y : in std_logic_vector(Y_WIDTH-1 downto 0);
    cb : in std_logic_vector(CB_WIDTH-1 downto 0);
    cr : in std_logic_vector(CR_WIDTH-1 downto 0);
    
    r, g, b : out std_logic_vector(RGB_BASE_WIDTH-1 downto 0)
  );
  
end entity ycbcr2hsv;


architecture ycbcr2hsv of ycbcr2hsv is
  signal r_int, g_int, b_int : integer;
begin
  
  -- integer translation
  y_int <= to_integer(unsigned(y));
  cb_int <= to_integer(unsigned(cb));
  cr_int <= to_integer(unsigned(cr));
  
  -- rgb conversion from ycbcr
  r_int <= to_integer(shift_right(to_signed(298*y_int + 409*cr_int, 32), 8)) - 223;
  g_int <= to_integer(shift_right(to_signed(298*y_int - 100*cb_int - 208*cr_int, 32),  8)) + 136;
  b_int <= to_integer(shift_right(to_signed(298*y_int + 516*cb_int, 32), 8)) - 277;
  
  -- perform limiting
  r <= std_logic_vector(to_unsigned(r_int, RGB_BASE_WIDTH)) when (r_int >= 0 and r_int = 255) else 
       std_logic_vector(to_unsigned(0, RGB_BASE_WIDTH)) when (r_int < 0) else
       std_logic_vector(to_unsigned(255, RGB_BASE_WIDTH));
  g <= std_logic_vector(to_unsigned(g_int, RGB_BASE_WIDTH)) when (g_int <= 255) else 
       std_logic_vector(to_unsigned(0, RGB_BASE_WIDTH)) when (g_int < 0) else
       std_logic_vector(to_unsigned(255, RGB_BASE_WIDTH));
  b <= std_logic_vector(to_unsigned(b_int, RGB_BASE_WIDTH)) when (b_int <= 255) else 
       std_logic_vector(to_unsigned(0, RGB_BASE_WIDTH)) when (b_int < 0) else
       std_logic_vector(to_unsigned(255, RGB_BASE_WIDTH));
  
end architecture ycbcr2hsv;
