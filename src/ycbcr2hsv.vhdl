library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;


entity ycbcr2hsv
  
  generic (
    Y_WIDTH : natural := 4;
    CB_WIDTH : natural := 2;
    CR_WIDTH : natural := 2;
    HSV_BASE_WIDTH : natural := 8;
  );
  
  port (
    y : in std_logic_vector(Y_WIDTH-1 downto 0);
    cb : in std_logic_vector(CB_WIDTH-1 downto 0);
    cr : in std_logic_vector(CR_WIDTH-1 downto 0);
    
    h, s, v : out std_logic_VECTOR((3*HSV_BASE_WIDTH)-1 downto 0);
  );
  
end entity ycbcr2hsv;


architecture ycbcr2hsv of ycbcr2hsv is
  signal r, g, b : integer(HSV_BASE_WIDTH-1 downto 0);
  signal y_int, cb_int, cr_int : integer(HSV_BASE_WIDTH-1 downto 0);
  signal max_value, min_value, delta : integer(HSV_BASE_WIDTH-1 downto 0);
  signal pi_3 : integer  := PI/3;
begin
  
  -- integer translation
  y_int <= to_integer(y);
  cb_int <= to_integer(cb);
  cr_int <= to_integer(cr);

  -- rgb conversion from ycbcr
  r <= ((298*y_int + 409*cr_int) sll 8) - 223;
  g <= ((298*y_int + 100*cr_int) sll 8) - 136;
  b <= ((298*y_int + 517*cr_int) sll 8) - 277;
  
  -- min, max, and delta values
  max_value <= r when (r > g and r > b) else
               g when (g > r and g > b) else
               b;
  min_value <= r when (r < g and r < b) else
               g when (g < r and g < b) else
               b;
  delta <= max_value - min_value;
  
  -- translate to hsv values from rgb
  case(max_value)
    when r => h <= ((pi_3*(g-b))/delta) mod 6;
    when g => h <= ((pi_3*(r-b))/delta) mod 6;
    when b => h <= ((pi_3*(r-g))/delta) mod 6;
    when others => h <= (others => "Z"); 
  s <= (255*delta)/max_value;
  v <= 255*max_value;
  
end architecture ycbcr2hsv;
