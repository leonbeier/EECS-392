library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_out is
	port(
			clk : in std_logic;
			reset : in std_logic;
			
			--VGA 
			red, green, blue : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk : out std_logic
			
		);
end entity video_out;

architecture structural of video_out is
  
  constant FULL_WIDTH : natural := 640;
  constant FULL_HEIGHT : natural := 480;
  constant IMG_WIDTH : natural := FULL_WIDTH / 2;
  constant IMG_HEIGHT : natural := FULL_HEIGHT / 2;
  constant IMG_SIZE : natural := IMG_WIDTH * IMG_HEIGHT;
  constant RAM_SIZE : natural := IMG_SIZE / 2;
  constant BW_BUFFER_WIDTH : natural := 8;
  constant BW_RAM_SIZE : natural := RAM_SIZE / BW_BUFFER_WIDTH;
  constant PIXEL_WIDTH : natural := 24;
  constant YCC_WIDTH : natural := 32;
  constant SAMPLE_WIDTH : natural := 8;
  
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

component sdram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk: in std_logic;
    we : in std_logic;
	 re : in std_logic;
    write_addr: in natural range 0 to RAM_SIZE-1;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr: in natural range 0 to RAM_SIZE-1;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component sdram;

component sram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk: in std_logic;
    we : in std_logic;
    write_addr: in natural range 0 to RAM_SIZE-1;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr: in natural range 0 to RAM_SIZE-1;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component sram;

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

signal pixel : std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal pixel_load : std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal we, re : std_logic := '1';
signal hori_sync, vert_sync : std_logic;

signal pixel_clk : std_logic;
signal pixel_row : std_logic_vector(9 downto 0);
signal pixel_col : std_logic_vector(9 downto 0);
signal pixel_row_int, pixel_col_int : natural;

signal ycc_store, ycc_load : std_logic_vector(YCC_WIDTH-1 downto 0);
signal y, y1, y2, cb, cr : std_logic_vector(SAMPLE_WIDTH-1 downto 0);
signal y_int, cb_int, cr_int : natural;
signal y_sel : std_logic := '0';

signal row, col : natural;
signal write_addr, read_addr, r_addr : natural;
signal img_sel : std_logic_vector(1 downto 0);

signal bw_buffer, bw_load : std_logic_vector(BW_BUFFER_WIDTH-1 downto 0);
signal bw_write_addr, bw_read_addr : natural;
signal bw_wr_en : std_logic;
signal filter_result : std_logic;

begin

  video : vga 
  port map(
    clk => clk, 
    reset => reset, 
    pixel => pixel, 
    pixel_clock_out => pixel_clk, 
    pixel_row => pixel_row, 
    pixel_col => pixel_col, 
    horiz_sync_out => hori_sync, 
    vert_sync_out => vert_sync, 
    vga_blank => blank, 
    red => red, 
    green => green, 
    blue => blue 
  );
  
  h_sync <= hori_sync;
  v_sync <= vert_sync;
  
  vga_clk <= pixel_clk;
  
  ycc_mem : sram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => YCC_WIDTH
  )
  port map(
    clk => clk,
    we => '1', -- we,
	 --re => re,
    write_addr => write_addr,
    data_in => ycc_store,
    read_addr => read_addr,
    data_out => ycc_load
  );
  
  -- determine row and column of single image
  pixel_row_int <= to_integer(unsigned(pixel_row));
  pixel_col_int <= to_integer(unsigned(pixel_col)); 
  row <= pixel_row_int mod IMG_HEIGHT;
  col <= pixel_col_int mod IMG_WIDTH;
  
  re <= hori_sync and vert_sync;
  
  read_addr <= r_addr mod RAM_SIZE;
  
  -- each address holds data for 2 pixels, so ignore least significant bit
  --read_addr <= to_integer(shift_left(shift_right(to_signed(row * IMG_WIDTH + col, 32), 1), 1));
  r_addr <= row * IMG_WIDTH + col;
  --read_addr_full <= to_unsigned(row * IMG_WIDTH + col, 32);
  --read_addr <= to_integer(read_addr_full(31 downto 1) & '0');
	
  -- map loaded word to ycc data
  y1 <= ycc_load(YCC_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH);
  cb <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH*2);
  y2 <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH*2-1 downto YCC_WIDTH-SAMPLE_WIDTH*3);
  cr <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH*3-1 downto 0);
  
  -- generate y selection bit, needed because 2 y components are loaded at a time
  get_y_sel : process(pixel_clk)
  begin
    if rising_edge(pixel_clk) then
      y_sel <= not y_sel;
    end if;
  end process;
  
  -- select which y component to convert
  with y_sel select y <=
    y1 when '0',
    y2 when '1',
    (others => '0') when others;
  
  -- convert current ycc to rgb for vga output
  get_colors : ycc2rgb
  port map(
    clk => clk, 
    y => y, 
    cb => cb, 
    cr => cr, 
    r => pixel_load(PIXEL_WIDTH-1 downto PIXEL_WIDTH-SAMPLE_WIDTH), 
    g => pixel_load(PIXEL_WIDTH-SAMPLE_WIDTH-1 downto PIXEL_WIDTH-SAMPLE_WIDTH*2), 
    b => pixel_load(PIXEL_WIDTH-SAMPLE_WIDTH*2-1 downto 0)
  );
  
  -- output depends on current quadrant of screen
  select_img : process(pixel_col_int, pixel_row_int)
  begin
    if (pixel_col_int < 320) then
      img_sel(0) <= '0';
    else
      img_sel(0) <= '1';
    end if;
    
    if (pixel_row_int < 240) then
      img_sel(1) <= '0';
    else
      img_sel(1) <= '1';
    end if;
  end process;
  
  with img_sel select pixel <=
    pixel_load when "00",
	 pixel_load when "01",
	 pixel_load when "10",
	 pixel_load when "11",
    (others => '1') when others;
    
  -- fill ycc RAM with test data
  fill_ram : process(clk, reset)
    constant RED_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"515A51F0"; -- 81 90 240
    constant GREEN_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"91369122"; -- 145 54 34
    constant BLUE_PIXEL : std_logic_vector(YCC_WIDTH-1 downto 0) := x"29F0296E"; -- 41 240 110
	 variable addr : natural := 0;
    variable color : std_logic_vector(YCC_WIDTH-1 downto 0) := RED_PIXEL;
	 variable w_en : std_logic := '1';
  begin
    if (reset = '0') then
      addr := 0;
      color := RED_PIXEL;
		  w_en := '1';
		
    elsif rising_edge(clk) then
      addr := addr + 1;
      
   --   if (addr >= RAM_SIZE) then
   --     addr := 0;
   --     color := RED_PIXEL;
   --   elsif (addr >= RAM_SIZE * 2/3) then
   --     color := GREEN_PIXEL;
   --   elsif (addr >= RAM_SIZE / 3) then
   --     color := BLUE_PIXEL;
   --   else
   --     color := RED_PIXEL;
   
		  if (addr >= RAM_SIZE) then
		  	addr := 0;
		  	w_en := '0';
		  end if;
        
      if (addr < RAM_SIZE / 3) then
        color := RED_PIXEL;
      elsif (addr < RAM_SIZE * 2/3) then
        color := GREEN_PIXEL;
      elsif (addr < RAM_SIZE) then
        color := BLUE_PIXEL;
      end if;
		
      write_addr <= addr;
      ycc_store <= color;
		  we <= w_en;
		
    end if;
  end process;
  
  y_int <= to_integer(unsigned(y));
  cb_int <= to_integer(unsigned(cb));
  cr_int <= to_integer(unsigned(cr));
  
  filter : ycc_filter
  port map(
    clk => clk,
    y => y_int,
    cb => cb_int,
    cr => cr_int,
    y_key => 81,
    cb_key => 90,
    cr_key => 240,
    result => filter_result
  );
  
  bw_mem : sram
  generic map(
    RAM_SIZE => BW_RAM_SIZE,
    DATA_WIDTH => SAMPLE_WIDTH
  )
  port map(
    clk => clk,
    we => bw_wr_en,
    write_addr => bw_write_addr,
    data_in => bw_buffer,
    read_addr => bw_read_addr,
    data_out => bw_load
  );
  
  fill_bw_buffer : process(pixel_clk, reset)
    variable counter : natural := 0;
    variable addr : natural := 0;
  begin
    if (reset = '0') then
      counter := 0;
      addr := 0;
    elsif rising_edge(pixel_clk) then
      bw_buffer <= bw_buffer(SAMPLE_WIDTH-2 downto 0) & filter_result;
      counter := counter + 1;
      bw_wr_en <= '0';
      if (counter >= SAMPLE_WIDTH) then
        bw_wr_en <= '1';
        counter := 0;
        addr := addr + 1;
        if (addr >= BW_RAM_SIZE) then
          addr := 0;
        end if;
      end if;
    end if;
  end process;
    
	
end architecture structural;

