library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use STD.textio.all;
use WORK.tracker_constants.all;

entity final_tb is
end entity final_tb;

architecture final_tb of final_tb is

  component rgb2hsv is
    port (
      clk, reset : in std_logic;
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

  component centroid is
    generic(
      ROWS : natural := 240;
      COLS : natural := 320
    ); 
    port(
      clk : in std_logic;
      reset : in std_logic;
      pixel : in std_logic;

      center_row : out natural;
      center_col : out natural;
      complete : out std_logic
    );
  end component;

  component filter_basic is
    port(
      clk : in std_logic;
      value : in integer;
      key : in integer;
      tolerance : in integer;
      result : out std_logic
    );
  end component;

  -- simulation
  signal sim_clk, sim_reset : std_logic;

  -- centroid
  signal centroid_clk : std_logic := '1';
  signal centroid_pixel : std_logic;
  signal centroid_reset, centroid_complete : std_logic;
  signal centroid_row, centroid_col : natural;

  -- ram
  signal ram_we : std_logic;
  signal ram_write_addr, ram_read_addr : natural;
  signal ram_din, ram_dout : std_logic_vector(23 downto 0);
  
  -- constants
  constant IMAGE_WIDTH : natural := 320;
  constant IMAGE_HEIGHT : natural := 240;
  constant IMAGE_DEPTH : natural := 3;
  constant IMAGE_SIZE : natural := IMAGE_WIDTH * IMAGE_HEIGHT;
  constant RAM_SIZE : natural := IMAGE_DEPTH * IMAGE_SIZE;
  constant DECODER_PERIOD : time := 37.037037037 ns;
  
  -- color conversion
  signal r, g, b : std_logic_vector(7 downto 0);
  signal h, s, v : std_logic_vector(7 downto 0);

  -- filter signals
  signal h_value, s_value, v_value : integer;
  signal h_key, s_key, v_key : integer;
  signal h_tolerance, s_tolerance, v_tolerance : integer;
  signal h_result, s_result, v_result : std_logic;

begin

  sim_reset <= '1';

  centroid_pixel <= h_result and s_result and v_result;

  -- create instance of final converter
  converter: rgb2hsv port map(sim_clk, sim_reset, r, g, b, h, s, v);

  ycbcr_ram: sram generic map(RAM_SIZE => IMAGE_SIZE, DATA_WIDTH => 24)
                  port map(sim_clk, sim_reset, ram_we, ram_write_addr, ram_din, ram_read_addr, ram_dout);

  centroid_algorithm: centroid generic map(ROWS => 240, COLS => 320)
                     port map(centroid_clk, centroid_reset, centroid_pixel, centroid_row, centroid_col);

  h_key <= 30;
  h_tolerance <= 6;
  s_key <= 190;
  s_tolerance <= 65;
  v_key <= 172;
  v_tolerance <= 72;

  h_filter: filter_basic port map(centroid_clk, h_value, h_key, h_tolerance, h_result);
  s_filter: filter_basic port map(centroid_clk, s_value, s_key, s_tolerance, s_result);
  v_filter: filter_basic port map(centroid_clk, v_value, v_key, v_tolerance, v_result);
  
  tb: process is
    variable inline, outline : line;
    file infile : text open read_mode is "final_input.txt";
    file outfile : text open write_mode is "final_output.txt";
    
    variable rows, cols : natural;
    variable r_data, g_data, b_data : integer;

    variable ram_address : natural := 0;
  begin
    readline(infile, inline);
    read(inline, rows);
    
    readline(infile, inline);
    read(inline, cols);
    
    write(outline, rows);
    writeline(outfile, outline);
    
    write(outline, cols);
    writeline(outfile, outline);
    
    ram_we <= '1';
    
    while not endfile(infile) loop
      -- buffer in the data
      readline(infile, inline);
      read(inline, r_data);
      
      readline(infile, inline);
      read(inline, g_data);
      
      readline(infile, inline);
      read(inline, b_data);
      
      sim_clk <= '0';
      ram_write_addr <= ram_address;
      
      -- conversion
      r <= std_logic_vector(to_unsigned(r_data, 8));
      g <= std_logic_vector(to_unsigned(g_data, 8));
      b <= std_logic_vector(to_unsigned(b_data, 8));
      
      wait for DECODER_PERIOD/2;
      sim_clk <= '1';
      wait for DECODER_PERIOD/2;
      ram_din <=  h & s & v;
      ram_address := ram_address + 1;
      
    end loop;
    
    ram_we <= '0';

    for i in 0 to RAM_SIZE-1 loop
      
      ram_read_addr <= i;
      sim_clk <= '0';
      centroid_clk <= '1';
      
      wait for DECODER_PERIOD/2;
      
      sim_clk <= '1';
      centroid_clk <= '0';

      h_value <= to_integer(unsigned(ram_dout(23 downto 16)));
      s_value <= to_integer(unsigned(ram_dout(15 downto 8)));
      v_value <= to_integer(unsigned(ram_dout(7 downto 0)));
      
      -- write out the hsv values
      write(outline, h_value);
      writeline(outfile, outline);
      
      write(outline, s_value);
      writeline(outfile, outline);
      
      write(outline, v_value);
      writeline(outfile, outline);

      wait for DECODER_PERIOD/2;
      
      centroid_clk <= '1';
      sim_clk <= '0';

      wait for DECODER_PERIOD/2;

      sim_clk <= '1';
      centroid_clk <= '0';
      
      wait for DECODER_PERIOD/2;
      
    end loop;

    write(outline, string'(""));
    writeline(outfile, outline);

    write(outline, centroid_row);
    writeline(outfile, outline);

    write(outline, centroid_col);
    writeline(outfile, outline);
    
    wait;
    
  end process tb;

end architecture final_tb;
