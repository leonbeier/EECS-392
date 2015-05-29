library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;


entity ycbcr2hsv is
  
  generic (
    RGB_BASE_WIDTH : natural := 8;
    HSV_BASE_WIDTH : natural := 8
  );
  
  port (
    r, g, b : in std_logic_vector(RGB_BASE_WIDTH-1 downto 0);
    h, s, v : out std_logic_vector(HSV_BASE_WIDTH-1 downto 0)
  );
  
end entity ycbcr2hsv;


architecture ycbcr2hsv of ycbcr2hsv is
  signal r_int, g_int, b_int : integer;
  signal max_value, min_value, delta : integer;
  signal h_value, s_value, v_value : unsigned(HSV_BASE_WIDTH-1 downto 0);
begin
  -- rgb conversion from ycbcr
  r_int <= to_integer(unsigned(r));
  g_int <= to_integer(unsigned(g));
  b_int <= to_integer(unsigned(b));
  
  -- min, max, and delta values
  max_value <= r_int when (r_int > g_int and r_int > b_int) else
               g_int when (g_int > r_int and g_int > b_int) else
               b_int;
  min_value <= r_int when (r_int < g_int and r_int < b_int) else
               g_int when (g_int < r_int and g_int < b_int) else
               b_int;
  
  -- converion signals
  h_value <= to_unsigned(((30*(g_int-b_int))/delta mod 45900)/255, HSV_BASE_WIDTH) when (r_int = max_value and delta /= 0) else
             to_unsigned((30*(b_int-r_int))/delta + 60, HSV_BASE_WIDTH) when (g_int = max_value and delta /= 0) else
             to_unsigned((30*(r_int-g_int))/delta + 120, HSV_BASE_WIDTH) when (b_int = max_value and delta /= 0) else
             to_unsigned(0, HSV_BASE_WIDTH);
  s_value <= to_unsigned((255*delta)/max_value, HSV_BASE_WIDTH) when (max_value /= 0) else to_unsigned(0, HSV_BASE_WIDTH);
  v_value <= to_unsigned(max_value, HSV_BASE_WIDTH);
  
  -- perform limiting
  h <= std_logic_vector(h_value) when (h_value <= 180) else std_logic_vector(to_unsigned(180, HSV_BASE_WIDTH));
  s <= std_logic_vector(s_value) when (s_value <= 255) else std_logic_vector(to_unsigned(255, HSV_BASE_WIDTH));
  v <= std_logic_vector(v_value) when (v_value <= 255) else std_logic_vector(to_unsigned(255, HSV_BASE_WIDTH));
  
end architecture ycbcr2hsv;
