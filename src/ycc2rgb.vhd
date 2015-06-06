library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- 8 bit images
entity ycc2rgb is
  port (
    clk : in std_logic;
    y, cb, cr : in std_logic_vector(7 downto 0);
    r, g, b : out std_logic_vector(7 downto 0)
  ); 
end entity ycc2rgb;

architecture dataflow of ycc2rgb is
  signal y_int, cb_int, cr_int : integer;
  signal r_int, g_int, b_int : integer;
begin

  y_int <= to_integer(unsigned(y));
  cb_int <= to_integer(unsigned(cb));
  cr_int <= to_integer(unsigned(cr));
  
  r_int <= to_integer(shift_right(to_signed(298*y_int + 409*cr_int, 32), 8)) - 223;
  g_int <= to_integer(shift_right(to_signed(298*y_int - 100*cb_int - 208*cr_int, 32),  8)) + 136;
  b_int <= to_integer(shift_right(to_signed(298*y_int + 516*cb_int, 32), 8)) - 277;
  
  gen_output : process(clk)
    variable red, green, blue : signed(8 downto 0);
  begin
    if rising_edge(clk) then
      red := to_signed(r_int, 9);
      green := to_signed(g_int, 9);
      blue := to_signed(b_int, 9);
      
      r <= std_logic_vector(red(7 downto 0)) when (red >= 0) else (others => '0')
      g <= std_logic_vector(green(7 downto 0)) when (green >= 0) else (others => '0')
      b <= std_logic_vector(blue(7 downto 0)) when (blue >= 0) else (others => '0')
    end if;
  end process;
  
end architecture dataflow;
