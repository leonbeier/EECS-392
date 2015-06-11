library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.tracker_constants.all;

entity rgb2hsv_tb is
end entity rgb2hsv_tb;

architecture rgb2hsv_tb of rgb2hsv_tb is

  component rgb2hsv is
    port (
      r, g, b : in std_logic_vector(7 downto 0);
      h, s, v : out std_logic_vector(7 downto 0)
    );	
  end component rgb2hsv;

  component sram is
    generic(
      RAM_SIZE: natural := 128;
      DATA_WIDTH : natural := 32 
    );
    port(
      clk, reset : in std_logic;
      we : in std_logic;
      write_addr : in natural range 0 to RAM_SIZE-1;
      data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      read_addr : in natural range 0 to RAM_SIZE-1;
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

  -- ram
  signal ram_clk, ram_reset, ram_we ; std_logic;
  signal ram_write_addr, ram_read_addr : natural;
  signal ram_din, ram_dout : std_logic_vector(23 downto 0);
  
  -- constants
  constant IMAGE_WIDTH : natural := ;
  constant IMAGE_HEIGHT : natural := ;
  
  -- color conversion
  signal r, g, b : std_logic_vector(7 downto 0);
  signal h, s, v : std_logic_vector(7 downto 0);

begin
  -- create instance of rgb2hsv converter
  converter: rgb2hsv port map(r, g, b, h, s, v);

  ycbcr_ram: sram generic map(RAM_SIZE => , DATA_WIDTH => 24)
                  port map(ram_clk, ram_reset, ram_we, ram_write_addr, ram_din, ram_dout);
  
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
      
      ram_clk <= '0';
      ram_write_addr <= ram_address;
      
      -- conversion
      r <= std_logic_vector(to_unsigned(r_data, 8));
      g <= std_logic_vector(to_unsigned(g_data, 8));
      b <= std_logic_vector(to_unsigned(b_data, 8));
      
      ram_din <=  r & g & b;

      wait for DECODER_PERIOD/2;
      ram_clk <= '1';
      wait for DECODER_PERIOD/2;
      ram_address := ram_address + 1;
      
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
