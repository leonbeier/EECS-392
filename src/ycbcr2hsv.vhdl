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
    
    h, s, v : out std_logic_vector(HSV_BASE_WIDTH-1 downto 0)
  );
  
end entity ycbcr2hsv;


architecture ycbcr2hsv of ycbcr2hsv is
  signal r, g, b : integer;
  signal y_int, cb_int, cr_int : integer;
  signal max_value, min_value, delta : integer;
  signal h_value, s_value, v_value : unsigned(HSV_BASE_WIDTH-1 downto 0);
begin
  
  -- integer translation
  y_int <= to_integer(unsigned(y));
  cb_int <= to_integer(unsigned(cb));
  cr_int <= to_integer(unsigned(cr));
  
  -- rgb conversion from ycbcr
  r <= to_integer(shift_right(to_signed(298*y_int + 409*cr_int, 32), 8)) - 223;
  g <= to_integer(shift_right(to_signed(298*y_int - 100*cb_int - 208*cr_int, 32),  8)) + 136;
  b <= to_integer(shift_right(to_signed(298*y_int + 516*cb_int, 32), 8)) - 277;
  
  -- min, max, and delta values
  max_value <= r when (r > g and r > b) else
               g when (g > r and g > b) else
               b;
  min_value <= r when (r < g and r < b) else
               g when (g < r and g < b) else
               b;
  delta <= max_value - min_value;
  
  -- translate to hsv values from rgb
  --h <= std_logic_vector(to_unsigned((((30*(g-b))/delta))/PI_DIV mod 6, HSV_BASE_WIDTH)) when (r = max_value and delta /= 0) else
  --     std_logic_vector(to_unsigned((((30*(b-r))/delta)+ pi_3*2)/PI_DIV, HSV_BASE_WIDTH)) when (g = max_value and delta /= 0) else
  --     std_logic_vector(to_unsigned((((30*(r-g))/delta) + pi_3*4)/PI_DIV, HSV_BASE_WIDTH)) when (b = max_value and delta /= 0) else
  --     (others => '0');
  
  -- h <= std_logic_vector(to_unsigned(((30*(g-b))/delta mod 45900)/255, HSV_BASE_WIDTH)) when (r = max_value and delta /= 0) else
  --      std_logic_vector(to_unsigned((30*(b-r))/delta + 60, HSV_BASE_WIDTH)) when (g = max_value and delta /= 0) else
  --      std_logic_vector(to_unsigned((30*(r-g))/delta + 120, HSV_BASE_WIDTH)) when (b = max_value and delta /= 0) else
  --      (others => '0');
  
  -- converion signals
  h_value <= to_unsigned(((30*(g-b))/delta mod 45900)/255, HSV_BASE_WIDTH) when (r = max_value and delta /= 0) else
             to_unsigned((30*(b-r))/delta + 60, HSV_BASE_WIDTH) when (g = max_value and delta /= 0) else
             to_unsigned((30*(r-g))/delta + 120, HSV_BASE_WIDTH) when (b = max_value and delta /= 0) else
             to_unsigned(0, HSV_BASE_WIDTH);
  s_value <= to_unsigned((255*delta)/max_value, HSV_BASE_WIDTH) when (max_value /= 0) else to_unsigned(0, HSV_BASE_WIDTH);
  v_value <= to_unsigned(max_value, HSV_BASE_WIDTH);
  
  -- perform limiting
  h <= std_logic_vector(h_value) when (h_value <= 180) else std_logic_vector(to_unsigned(180, HSV_BASE_WIDTH));
  s <= std_logic_vector(s_value) when (s_value <= 255) else std_logic_vector(to_unsigned(255, HSV_BASE_WIDTH));
  v <= std_logic_vector(v_value) when (v_value <= 255) else std_logic_vector(to_unsigned(255, HSV_BASE_WIDTH));
  
end architecture ycbcr2hsv;
