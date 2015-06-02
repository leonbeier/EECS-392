library IEEE;
library IEEE_PROPOSED;

use IEEE.std_logic_1164.all;
use IEEE_PROPOSED.fixed_pkg.all;

entity sineLUT is
  generic(
    DECIMAL_WIDTH := 12,
    FRACTION_WIDTH := 20
  );
  
  port(
    latch : in std_logic;
    radians : in sfixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH), 
    sine : out sfixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH) 
  );
end entity sineLUT;

architecture sineLUT of sineLUT is
  signal normalized_radians : sfixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH);
  signal absolute_radians : sfixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH);
  signal wrapped_radians : sfixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH);
  signal sign : std_logic := '0';
  signal index : natural;
  signal wrapped_index : natural;
  signal usine : ufixed(DECIMAL_WIDTH-1 downto -FRACTION_WIDTH);
begin
  -- compute index into the LUT in ROM
  sign <= '0' when (radians >= 0) else '1';
  absolute_radians <= radians when (sign = '0') else -radians;
  wrapped_radians <= absolute_radians mod PI;
  index <= wrapped_radians / SINE_LUT_RESOLUTION;
  wrapped_index <= index when (index < SINE_LUT_LENGTH) else 2*SINE_LUT_LENGTH-index;
  
  sine_rom: port map(std_logic_vector(to_unsigned(wrapped_index, ROM_DATA_WIDTH)), latch, sine);
  
end architecture sineLUT;
