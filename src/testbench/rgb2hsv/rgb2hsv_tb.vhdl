library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.tracker_constants.all;

entity rgb2hsv_tb is
end entity rgb2hsv_tb;

architecture rgb2hsv_tb of rgb2hsv_tb is
	component rgb2hsv is
	  generic (
      RGB_BASE_WIDTH : natural := 8;
      HSV_BASE_WIDTH : natural := 8
    );
    
    port (
      r, g, b : in std_logic_vector(RGB_BASE_WIDTH-1 downto 0);
      h, s, v : out std_logic_vector(HSV_BASE_WIDTH-1 downto 0)
    );	
  end component rgb2hsv;
  
  signal r, g, b : std_logic_vector(9 downto 0);
  signal h, s, v : std_logic_vector(9 downto 0);
  
begin
  -- create instance of rgb2hsv converter
  converter: rgb2hsv generic map(RGB_BASE_WIDTH => 10, HSV_BASE_WIDTH => 10) 
                       port map(r, g, b, h, s, v);
  
  tb: process is
    variable inline, outline : line;
    file infile : text open read_mode is "rgb2hsv_input.txt";
    file outfile : text open write_mode is "rgb2hsv_output.txt";
    
    variable rows, cols : natural;
    variable r_data, g_data, b_data : integer;
  begin
    readline(infile, inline);
    read(inline, rows);
    
    readline(infile, inline);
    read(inline, cols);
    
    write(outline, rows);
    writeline(outfile, outline);
    
    write(outline, cols);
    writeline(outfile, outline);
    
    wait for 5 ns;
    
    while not endfile(infile) loop
      -- buffer in the data
      readline(infile, inline);
      read(inline, y_data);
      
      readline(infile, inline);
      read(inline, cb_data);
      
      readline(infile, inline);
      read(inline, cr_data);
      
      -- conversion
      r <= std_logic_vector(to_unsigned(r_data, 10));
      g <= std_logic_vector(to_unsigned(g_data, 10));
      b <= std_logic_vector(to_unsigned(b_data, 10));
      
      wait for 5 ns;
      
      write(outline, to_integer(unsigned(h)));
      writeline(outfile, outline);
      
      write(outline, to_integer(unsigned(s)));
      writeline(outfile, outline);
      
      write(outline, to_integer(unsigned(v)));
      writeline(outfile, outline);
      
    end loop;
    
    wait;
    
  end process tb;

end architecture rgb2hsv_tb;
