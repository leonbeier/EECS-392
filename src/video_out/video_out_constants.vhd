library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

package video_out_constants is

  constant FULL_WIDTH : natural := 640;
  constant FULL_HEIGHT : natural := 480;
  constant IMG_WIDTH : natural := FULL_WIDTH / 2;
  constant IMG_HEIGHT : natural := FULL_HEIGHT / 2;
  constant IMG_SIZE : natural := IMG_WIDTH * IMG_HEIGHT;
  constant YCC_RAM_SIZE : natural := IMG_SIZE / 2;
  constant BW_BUFFER_WIDTH : natural := 8;
  constant BW_RAM_SIZE : natural := IMG_SIZE / BW_BUFFER_WIDTH;
  constant PIXEL_WIDTH : natural := 24;
  constant YCC_WIDTH : natural := 32;
  constant SAMPLE_WIDTH : natural := 8;
  
  constant RED_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"515A51F0"; -- 81 90 240
  constant GREEN_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"91369122"; -- 145 54 34
  constant BLUE_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"29F0296E"; -- 41 240 110
  
component vga is
	port(
			clk, reset	: in std_logic;
			pixel : in std_logic_vector(23 downto 0);
			pixel_clock_out	: out std_logic;												
			pixel_row, pixel_col	: out std_logic_vector(9 downto 0);
			horiz_sync_out, vert_sync_out : out std_logic; 
			vga_blank : out std_logic;
			red, green, blue : out std_logic_vector(7 downto 0)
		);					    		
end component vga;

component sram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk, we : in std_logic;
    write_addr : in natural range 0 to RAM_SIZE-1;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr : in natural range 0 to RAM_SIZE-1;
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component;

component ycc2rgb is
  port (
    clk : in std_logic;
    y, cb, cr : in std_logic_vector(7 downto 0);
    r, g, b : out std_logic_vector(7 downto 0)
  ); 
end component ycc2rgb;

component ycc_filter is
  port(
    clk : in std_logic;    
    y : in natural;
    cb : in natural;
    cr : in natural;
    y_key : in natural;
    cb_key : in natural;
    cr_key : in natural;
    result : out std_logic
  );
end component ycc_filter;

component pixel_address is
  port(
    pixel_row : in natural;
    pixel_col : in natural;
    
    ycc_read_addr : out natural;
    ycc_pixel_sel : out std_logic;
    bw_read_addr : out natural;
    bw_pixel_sel : out natural
  );
end component;

component fifo is
  generic(
    constant BUFFER_SIZE : natural := 128;
    constant DATA_WIDTH : natural := 8
  );
  port(
    signal read_clk : in std_logic;
    signal write_clk : in std_logic;
    signal reset : in std_logic;
    signal read_en : in std_logic;
    signal write_en : in std_logic;
    signal data_in : in std_logic_vector((DATA_WIDTH-1) downto 0);
    signal data_out : out std_logic_vector((DATA_WIDTH-1) downto 0);
    signal full : out std_logic;
    signal empty : out std_logic
  );
end component fifo;

component centroid is
  generic(
    ROWS : natural := 240;
    COLS : natural := 320;
    PIXEL_COUNT : natural := 2
  ); 
  port(
    clk : in std_logic;
    reset : in std_logic;
    enable : in std_logic;
    pixels : in std_logic_vector(PIXEL_COUNT-1 downto 0);
    
    center_row : out natural;
    center_col : out natural
  );
end component centroid;

component input_buffer is
  generic(
    DATA_WIDTH : natural := 8;
    BUFFER_WIDTH : natural := 32
  );
  port(
    clk, reset : std_logic;
    enable : std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(BUFFER_WIDTH-1 downto 0);
    ready : out std_logic
  );
end component;

component leddcd is
	port(
		 data_in : in std_logic_vector(3 downto 0);
		 segments_out : out std_logic_vector(6 downto 0)
		);
end component leddcd;	

component dual_port_ram is
	generic 
	(
		DATA_WIDTH : natural := 32;
		RAM_SIZE : natural := 128
	);
	port 
	(
		rclk	: in std_logic;
		wclk	: in std_logic;
		read_addr	: in natural range 0 to RAM_SIZE-1;
		write_addr	: in natural range 0 to RAM_SIZE-1;
		we		: in std_logic := '1';
		data_in	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		data_out	: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);
end component;
  
end package;