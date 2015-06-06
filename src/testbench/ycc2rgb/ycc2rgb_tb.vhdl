library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.tracker_constants.all;

entity ycc2rgb_tb is
end entity ycc2rgb_tb;

architecture ycc2rgb_tb of ycc2rgb_tb is
	component ycc2rgb is
    port (
      y : in std_logic_vector(7 downto 0);
      cb : in std_logic_vector(7 downto 0);
      cr : in std_logic_vector(7 downto 0);
      
      h, s, v : out std_logic_vector(7 downto 0)
    );	
  end component ycc2rgb;
  
  signal y, cb, cr : std_logic_vector(7 downto 0);
  signal r, g, b : std_logic_vector(7 downto 0);
  
begin
  -- create instance of ycc2rgb converter
  converter: ycc2rgb port map(y, cb, cr, h, s, v);
  
  tb: process is
    variable inline, outline : line;
    file infile : text open read_mode is "ycc2rgb_input.txt";
    file outfile : text open write_mode is "ycc2rgb_output.txt";
    
    variable rows, cols : natural;
    variable y_data, cb_data, cr_data : integer;
    variable y_sig, cb_sig, cr_sig : std_logic_vector(7 downto 0);
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
      y <= std_logic_vector(to_unsigned(y_data, 8));
      cb <= std_logic_vector(to_unsigned(cb_data, 8));
      cr <= std_logic_vector(to_unsigned(cr_data, 8));
      
      wait for 5 ns;
      
      write(outline, to_integer(unsigned(r)));
      writeline(outfile, outline);
      
      write(outline, to_integer(unsigned(g)));
      writeline(outfile, outline);
      
      write(outline, to_integer(unsigned(b)));
      writeline(outfile, outline);
      
    end loop;
    
    wait;
    
  end process tb;

end architecture ycc2rgb_tb;
