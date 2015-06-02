library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.tracker_constants.all;

entity ycbcr2rgb_tb is
end entity ycbcr2rgb_tb;

architecture ycbcr2rgb_tb of ycbcr2rgb_tb is
	component ycbcr2rgb is
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
      
      h, s, v : out std_logic_vector(RGB_BASE_WIDTH-1 downto 0)
    );	
  end component ycbcr2rgb;
  
  signal y : std_logic_vector(15 downto 0);
  signal cb, cr : std_logic_vector(7 downto 0);
  signal r, g, b : std_logic_vector(9 downto 0);
  
begin
  -- create instance of ycbcr2rgb converter
  converter: ycbcr2rgb generic map(Y_WIDTH => 16, CB_WIDTH => 8, CR_WIDTH => 8, RGB_BASE_WIDTH => 10) 
                       port map(y, cb, cr, h, s, v);
  
  tb: process is
    variable inline, outline : line;
    file infile : text open read_mode is "ycbcr2rgb_input.txt";
    file outfile : text open write_mode is "ycbcr2rgb_output.txt";
    
    variable rows, cols : natural;
    variable y_data, cb_data, cr_data : integer;
    variable y_sig : std_logic_vector(15 downto 0);
    variable cb_sig, cr_sig : std_logic_vector(7 downto 0);
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
      y <= std_logic_vector(to_unsigned(y_data, 16));
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

end architecture ycbcr2rgb_tb;
