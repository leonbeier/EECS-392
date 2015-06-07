library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;

entity video_display is
  
  port (
    -- fpga clock and active low reset button -------------------------------------------------------------------------
    clk50, reset : in std_logic;
    
    -- vga -------------------------------------------------------------------------
    vga_red, vga_green, vga_blue : out std_logic_vector(7 downto 0);
    vga_hs, vga_vs, vga_blank, vga_clk : out std_logic;
    
    -- adv7180 -------------------------------------------------------------------------
    td_clk27 : in std_logic;
    td_data : in std_logic_vector(7 downto 0);
    td_hs, td_vs : in std_logic;
	 td_reset : out std_logic
  );
  
end entity video_display;

architecture video_display of video_display is

  -- component declarations -------------------------------------------------------------------------
  component sram is
    generic(
      RAM_SIZE: natural := 128;
      DATA_WIDTH : natural := 32 
    );
	 
    port(
      clk, reset, we : in std_logic;
      write_addr : in natural range 0 to RAM_SIZE-1;
      data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
      read_addr : in natural range 0 to RAM_SIZE-1;
      data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component sram;

  component adv7180 is
    generic (
      DECIMATION_ROWS : natural := 1;
      DECIMATION_COLS : natural := 1
    );

    port (
      -- tv decoder -------------------------------------------------------------------------
      td_clk27 : in std_logic;
      td_data : in std_logic_vector(7 downto 0);
      td_hs, td_vs : in std_logic;
      td_reset : in std_logic;

      -- SRAM connections -------------------------------------------------------------------------
      ram_clk, ram_we : out std_logic;
      ram_din : out std_logic_vector(31 downto 0);
      ram_write_addr : out natural
    );
  end component adv7180;

  component vga is
    port(
      clk, reset                       : in std_logic;
      pixel                            : in std_logic_vector(23 downto 0);

      pixel_clock_out                  : out std_logic;                        
      pixel_row, pixel_col             : out std_logic_vector(9 downto 0);
      horiz_sync_out, vert_sync_out    : out std_logic; 
      vga_blank                        : out std_logic;
      red, green, blue                 : out std_logic_vector(7 downto 0)
    );                  
  end component vga;

  component ycc2rgb is
    port (
      clk, reset : in std_logic;
      y, cb, cr : in std_logic_vector(7 downto 0);
      r, g, b : out std_logic_vector(7 downto 0)
    ); 
  end component ycc2rgb;

  -- constants
  constant IMAGE_SIZE : natural := 38400;

  -- ram signals -------------------------------------------------------------------------
  signal ram_clk, ram_we : std_logic;
  signal ram_write_addr, ram_read_addr : natural;
  signal ram_din, ram_dout : std_logic_vector(31 downto 0);

  -- vga signals -------------------------------------------------------------------------
  signal vga_pixel_clk : std_logic;
  signal vga_pixel : std_logic_vector(23 downto 0);
  signal vga_pixel_row, vga_pixel_col : std_logic_vector(9 downto 0);
  signal vga_row_int, vga_col_int : natural;

  -- ycc2rgb signals -------------------------------------------------------------------------
  signal ycc_y, ycc_cb, ycc_cr : std_logic_vector(7 downto 0);
  signal red_out, green_out, blue_out : std_logic_vector(7 downto 0);

  -- temporary signals -------------------------------------------------------------------------
  signal ycbcr_pixel : std_logic_vector(31 downto 0);
  signal ycc_even : boolean := true;
  signal ycc_clk : std_logic;

begin
  
  -- concurrent signal assignments -------------------------------------------------------------------------
  ycc_y <= ram_dout(23 downto 16) when (ycc_even = true) else ram_dout(7 downto 0);
  ycc_cb <= ram_dout(31 downto 24);
  ycc_cr <= ram_dout(15 downto 8);
  ycc_clk <= not td_clk27;
  
  vga_clk <= vga_pixel_clk;
  vga_row_int <= to_integer(unsigned(vga_pixel_row));
  vga_col_int <= to_integer(unsigned(vga_pixel_col));
  
  td_reset <= reset;
  
  -- structural port maps -------------------------------------------------------------------------
  ram_block: sram generic map(DATA_WIDTH => 32, RAM_SIZE => IMAGE_SIZE)
                  port map(ram_clk, reset, ram_we, ram_write_addr, ram_din, ram_read_addr, ram_dout);
  
  decoder: adv7180 generic map(DECIMATION_ROWS => 2, DECIMATION_COLS => 2)
                   port map(td_clk27, td_data, td_hs, td_vs, reset, ram_clk, ram_we, ram_din, ram_write_addr);
  
  ycc2rgb_converter: ycc2rgb port map(ycc_clk, reset, ycc_y, ycc_cb, ycc_cr, red_out, green_out, blue_out);
  
  vga_output: vga port map(clk50, reset, vga_pixel, vga_pixel_clk, vga_pixel_row, vga_pixel_col, vga_hs, vga_vs, vga_blank, vga_red, vga_green, vga_blue);
  
  -- ram address update -------------------------------------------------------------------------
  ram_read_manager: process(vga_pixel_clk, reset) is
  begin
    if(reset = '0') then
      -- active low reset
      ram_read_addr <= 0;
      ycc_even <= true;
    elsif(rising_edge(vga_pixel_clk)) then
      ram_read_addr <= ((vga_row_int * IMAGE_WIDTH) + vga_col_int)/4;
      case(ram_read_addr mod 2) is
        when 1 => ycc_even <= false;
        when others => ycc_even <= true;
      end case;
      vga_pixel <= red_out & green_out & blue_out;
    end if;
  end process;
  
end architecture;
