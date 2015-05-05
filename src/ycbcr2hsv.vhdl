library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;

entity ycbcr2hsv is
  
  generic (
    Y_WIDTH : natural := 4;
    CB_WIDTH : natural := 2;
    CR_WIDTH : natural := 2;
    HSV_BASE_WIDTH : natural := 8
  );
  
  port (
    y : in std_logic_vector(Y_WIDTH-1 downto 0);
    cb : in std_logic_vector(CB_WIDTH-1 downto 0);
    cr : in std_logic_vector(CR_WIDTH-1 downto 0);
    
    h, s, v : out std_logic_vector((3*HSV_BASE_WIDTH)-1 downto 0)
  );
  
end entity ycbcr2hsv;


architecture ycbcr2hsv of ycbcr2hsv is
  signal r, g, b : integer;
  signal r_itemp, g_itemp, b_itemp : integer;
  signal r_utemp, g_utemp, b_utemp : unsigned(31 downto 0);
  signal r_iconv, g_iconv, b_iconv : unsigned(32 downto 0);
  signal y_int, cb_int, cr_int : integer;
  signal max_value, min_value, delta : integer;
  signal pi_3 : integer  := PI/3;
begin
  
  -- integer translation
  y_int <= to_integer(unsigned(y));
  cb_int <= to_integer(unsigned(cb));
  cr_int <= to_integer(unsigned(cr));
  
  -- rgb conversion from ycbcr
  r <= to_integer(to_unsigned(298*y_int + 409*cr_int, 32) sll 8) - 223;
  g <= to_integer(to_unsigned(298*y_int + 100*cr_int, 32) sll 8) - 136;
  b <= to_integer(to_unsigned(298*y_int + 517*cr_int, 32) sll 8) - 277;
  
  -- min, max, and delta values
  max_value <= r when (r > g and r > b) else
               g when (g > r and g > b) else
               b;
  min_value <= r when (r < g and r < b) else
               g when (g < r and g < b) else
               b;
  delta <= max_value - min_value;
  
  -- translate to hsv values from rgb
  h <= std_logic_vector(to_unsigned((((pi_3*(g-b))/delta))/PI_DIV mod 6, HSV_BASE_WIDTH)) when (r = max_value) else
       std_logic_vector(to_unsigned((((pi_3*(r-b))/delta))/PI_DIV mod 6, HSV_BASE_WIDTH)) when (g = max_value) else
       std_logic_vector(to_unsigned((((pi_3*(r-g))/delta))/PI_DIV mod 6, HSV_BASE_WIDTH)) when (b = max_value) else
       (others => 'Z');
  s <= std_logic_vector(to_unsigned((255*delta)/max_value, HSV_BASE_WIDTH));
  v <= std_logic_vector(to_unsigned(255*max_value, HSV_BASE_WIDTH));
  
end architecture ycbcr2hsv;
