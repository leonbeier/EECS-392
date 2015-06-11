library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_out_constants.all;

entity video_out is
	port(
			clk : in std_logic;
			clk_27 : in std_logic;
			reset : in std_logic;
			
			--VGA 
			red, green, blue : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk : out std_logic;
			
			led0, led1, led2, led3, led4, led5, led6, led7 : out std_logic_vector(6 downto 0)		
		);
end entity video_out;

architecture top_level of video_out is
  
constant y_key : natural := 81;
constant cb_key : natural := 90;
constant cr_key : natural := 240;

signal pixel_clk : std_logic;
signal pixel_row : std_logic_vector(9 downto 0);
signal pixel_col : std_logic_vector(9 downto 0);
signal pixel_row_int, pixel_col_int : natural;
signal hori_sync, vert_sync : std_logic;

signal ycc_store, ycc_load : std_logic_vector(YCC_WIDTH-1 downto 0);
signal ycc_store_temp : std_logic_vector(YCC_WIDTH-1 downto 0);
signal y, y1, y2, cb, cr : std_logic_vector(SAMPLE_WIDTH-1 downto 0);
signal y1_filter, y2_filter, cb_filter, cr_filter : std_logic_vector(SAMPLE_WIDTH-1 downto 0);
signal y_int, cb_int, cr_int : natural;
signal y1_filter_int, y2_filter_int, cb_filter_int, cr_filter_int : natural;
signal filter_result : std_logic_vector(1 downto 0);
--signal filter_result_first, filter_result_last : std_logic;

signal row, col : natural;
--signal read_addr_full : signed(31 downto 0);
signal ycc_write_addr, ycc_read_addr : natural;
signal img_sel : std_logic_vector(1 downto 0);

signal pixel : std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal ycc_pixel : std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal ycc_pixel_sel : std_logic;
signal bw_pixel_full : std_logic_vector(PIXEL_WIDTH-1 downto 0);
signal bw_pixel : std_logic;
signal bw_pixel_sel : natural;

signal bw_store, bw_load : std_logic_vector(BW_BUFFER_WIDTH-1 downto 0);
signal bw_write_addr, bw_read_addr : natural;

signal camera_load : std_logic_vector(SAMPLE_WIDTH-1 downto 0);
signal camera_store : std_logic_vector(SAMPLE_WIDTH-1 downto 0) := x"00";
signal full, empty : std_logic;
signal fifo_read_en, fifo_write_en : std_logic := '0';

signal center_row, center_col : natural;
signal centroid_in : std_logic_vector(1  downto 0);
signal centroid_enable : std_logic := '0';

signal ycc_ready, buffer_latch : std_logic := '0';
signal ycc_write_en : std_logic := '1';
signal bw_write_en : std_logic := '1';

signal ycc_read_addr_temp : natural;
signal ycc_ready_latched : std_logic := '0';

signal clk_n : std_logic;

signal buffer_enable : std_logic := '0';
signal address_update : std_logic := '0';

signal bw_buffer_en : std_logic := '0';

begin
  
---- structural ----------

  input_stream : fifo
  generic map(
    BUFFER_SIZE => 8,
    DATA_WIDTH => SAMPLE_WIDTH 
  )
  port map(
    read_clk => clk,
    write_clk => clk_27,
    reset => reset,
    read_en => buffer_latch,
    write_en => fifo_write_en,
    data_in => camera_store,
    data_out => camera_load,
    full => full,
    empty => empty
  );
  
  in_buffer : input_buffer
  generic map(
    DATA_WIDTH => SAMPLE_WIDTH,
    BUFFER_WIDTH => SAMPLE_WIDTH * 4
  )
  port map(
    clk => clk,
    reset => reset,
    enable => buffer_latch,
    data_in => camera_load,
    data_out => ycc_store_temp,
    ready => ycc_ready
  );
  
--  buffer_dual : input_buffer
--  generic map(
--    DATA_WIDTH => SAMPLE_WIDTH,
--    BUFFER_WIDTH => SAMPLE_WIDTH * 4
--  )
--  port map(
--    clk => clk_27,
--    reset => reset,
--    enable => buffer_enable,
--    data_in => camera_store,
--    data_out => ycc_store_temp,
--    ready => ycc_ready
--  );

--  ycc_dual : dual_port_ram
--  generic map(
--    DATA_WIDTH => YCC_WIDTH,
--    RAM_SIZE => YCC_RAM_SIZE
--  )
--  port map(
--    rclk => clk,
--    wclk => clk_27,
--    read_addr => ycc_read_addr,
--    write_addr => ycc_write_addr,
--    we => ycc_ready,
--    data_in => ycc_store,
--    data_out => ycc_load 
--  );

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
  
  ycc_mem : sram
  generic map(
    RAM_SIZE => YCC_RAM_SIZE,
    DATA_WIDTH => YCC_WIDTH
  )
  port map(
    clk => clk,
    we => ycc_write_en, -- ycc_ready
    write_addr => ycc_write_addr,
    data_in => ycc_store,
    read_addr => ycc_read_addr,
    data_out => ycc_load
  );

  -- determine read address for ycc and bw memories
  get_addr : pixel_address
  port map(
    pixel_row => row,
    pixel_col => col,
    ycc_read_addr => ycc_read_addr,
    ycc_pixel_sel => ycc_pixel_sel,
    bw_read_addr => bw_read_addr,
    bw_pixel_sel => bw_pixel_sel
  );
  
  -- convert current ycc to rgb for vga output
  get_colors : ycc2rgb
  port map(
    clk => clk_n, 
    y => y, 
    cb => cb, 
    cr => cr, 
    r => ycc_pixel(PIXEL_WIDTH-1 downto PIXEL_WIDTH-SAMPLE_WIDTH), 
    g => ycc_pixel(PIXEL_WIDTH-SAMPLE_WIDTH-1 downto PIXEL_WIDTH-SAMPLE_WIDTH*2), 
    b => ycc_pixel(PIXEL_WIDTH-SAMPLE_WIDTH*2-1 downto 0)
  );
  
  get_center : centroid
  port map(
    clk => pixel_clk, 
    reset => reset,
    enable => '1', --centroid_enable,
    pixels => centroid_in, 
    center_row => center_row,
    center_col => center_col
  );
  
  filter_first : ycc_filter
  port map(
    clk => clk,
    y => y1_filter_int,
    cb => cb_filter_int,
    cr => cr_filter_int,
    y_key => y_key,
    cb_key => cb_key,
    cr_key => cr_key,
    result => filter_result(0)
  );
  
  filter_last : ycc_filter
  port map(
    clk => clk,
    y => y2_filter_int,
    cb => cb_filter_int,
    cr => cr_filter_int,
    y_key => y_key,
    cb_key => cb_key,
    cr_key => cr_key,
    result => filter_result(1)
  );
  
  bw_mem : sram
  generic map(
    RAM_SIZE => BW_RAM_SIZE,
    DATA_WIDTH => SAMPLE_WIDTH
  )
  port map(
    clk => clk, 
    we => '1', --bw_write_en,
    write_addr => bw_write_addr,
    data_in => bw_store,
    read_addr => bw_read_addr,
    data_out => bw_load
  );


  
---- dataflow ----------
  
  clk_n <= not clk;
  
  vga_clk <= pixel_clk;
  h_sync <= hori_sync;
  v_sync <= vert_sync;
	
	row <= pixel_row_int mod IMG_HEIGHT;
  col <= pixel_col_int mod IMG_WIDTH;
  pixel_row_int <= to_integer(unsigned(pixel_row));
  pixel_col_int <= to_integer(unsigned(pixel_col));
	
  -- map loaded word to ycc data
  y1 <= ycc_load(YCC_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH);
  cb <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH*2);
  y2 <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH*2-1 downto YCC_WIDTH-SAMPLE_WIDTH*3);
  cr <= ycc_load(YCC_WIDTH-SAMPLE_WIDTH*3-1 downto 0);
  
  led_0 : leddcd port map(data_in => ycc_store(3 downto 0), segments_out => led0);
  led_1 : leddcd port map(data_in => ycc_store(7 downto 4), segments_out => led1);
  led_2 : leddcd port map(data_in => ycc_store(11 downto 8), segments_out => led2);
  led_3 : leddcd port map(data_in => ycc_store(15 downto 12), segments_out => led3);
  led_4 : leddcd port map(data_in => ycc_store(19 downto 16), segments_out => led4);
  led_5 : leddcd port map(data_in => ycc_store(23 downto 20), segments_out => led5);
  led_6 : leddcd port map(data_in => ycc_store(27 downto 24), segments_out => led6);
  led_7 : leddcd port map(data_in => ycc_store(31 downto 28), segments_out => led7);
    
  -- map store data to filters
  y1_filter <= ycc_store(YCC_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH);
  cb_filter <= ycc_store(YCC_WIDTH-SAMPLE_WIDTH-1 downto YCC_WIDTH-SAMPLE_WIDTH*2);
  y2_filter <= ycc_store(YCC_WIDTH-SAMPLE_WIDTH*2-1 downto YCC_WIDTH-SAMPLE_WIDTH*3);
  cr_filter <= ycc_store(YCC_WIDTH-SAMPLE_WIDTH*3-1 downto 0);
  y1_filter_int <= to_integer(unsigned(y1_filter));
  y2_filter_int <= to_integer(unsigned(y2_filter));
  cb_filter_int <= to_integer(unsigned(cb_filter));
  cr_filter_int <= to_integer(unsigned(cr_filter));
   
  -- select which y component to convert
  with ycc_pixel_sel select y <=
    y1 when '0',
    y2 when '1',
    (others => '0') when others;
    
  with img_sel select pixel <=
    ycc_pixel when "00",
    ycc_pixel when "01",
    --bw_pixel_full when "01",
    bw_pixel_full when "10",
    bw_pixel_full when "11",
    x"AAAAAA" when others;
  
  centroid_in <= filter_result;
  centroid_enable <= (hori_sync and vert_sync); -- active low signals
  
  bw_pixel <= bw_load(bw_pixel_sel);



---- behavioral ----------
  
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
  
  get_bw_pixel : process(row, col, bw_pixel)
  begin
    if (row >= center_row-1 and row <= center_row+1 and col >= center_col-1 and col <= center_col+1) then
      bw_pixel_full <= x"FF0000";
    else
      bw_pixel_full <= (others => bw_pixel);
    end if;
  end process;  
    
  -- fill ycc RAM with test data
--  fill_ram : process(clk, reset)
--    variable addr : natural := 0;
--    variable color : std_logic_vector(YCC_WIDTH-1 downto 0) := RED_PIXEL;
--  begin
--    if rising_edge(clk) then
--      addr := addr + 1;
--		  if (addr = YCC_RAM_SIZE) then
--		  	addr := 0;
--		  end if; 
--      if (addr < YCC_RAM_SIZE / 3) then
--        color := RED_PIXEL;
--      elsif (addr < YCC_RAM_SIZE * 2/3) then
--        color := GREEN_PIXEL;
--      elsif (addr < YCC_RAM_SIZE) then
--        color := BLUE_PIXEL;
--      end if;
--      if (reset = '0') then
--        addr := 0;
--        color := RED_PIXEL;
--      end if;    
--      ycc_write_addr <= addr;
--      ycc_store <= color;
--    end if;
--  end process;
  
    -- fill fifo with ycc test data
  write_fifo : process(clk_27, reset)
	 variable addr : natural := 0;
   variable color : std_logic_vector(YCC_WIDTH-1 downto 0) := RED_PIXEL;
   variable byte : natural := 3;
   variable write_en : std_logic := '0';
  begin
    if (reset = '0') then
      byte := 3;
      addr := 0;
     	color := RED_PIXEL;
     	write_en := '0';
    elsif falling_edge(clk_27) then
      write_en := '1';
			camera_store <= color((byte+1)*8-1 downto byte*8);
			if (byte = 0) then
			  byte := 3;
			  addr := addr + 1;
			  if (addr = YCC_RAM_SIZE) then
				 addr := 0;
			  end if;
			else
			  byte := byte - 1;
			end if;
			if (addr < YCC_RAM_SIZE / 3) then
			  color := RED_PIXEL;
			elsif (addr < YCC_RAM_SIZE * 2/3) then
			  color := GREEN_PIXEL;
			elsif (addr < YCC_RAM_SIZE) then
			  color := BLUE_PIXEL;
			end if;
			fifo_write_en <= write_en;
    end if;
  end process;

--  write_dual_ram : process(clk_27, reset)
--	 variable addr : natural := 0;
--   variable color : std_logic_vector(YCC_WIDTH-1 downto 0) := RED_PIXEL;
--   variable byte : natural := 3;
--  begin
--    if (reset = '0') then
--      byte := 3;
--      addr := 0;
--     	color := RED_PIXEL;
--    elsif rising_edge(clk_27) then
--			camera_store <= color((byte+1)*8-1 downto byte*8);
--			if (byte = 0) then
--			  byte := 3;
--			else
--			  byte := byte - 1;
--			end if;
--			
--			if (address_update = '1') then
--			  addr := addr + 1;
--			  if (addr = YCC_RAM_SIZE) then
--				 addr := 0;
--			  end if;
--			  address_update <= '0';
--			end if;
--			
--			if (ycc_ready = '1') then
--			  address_update <= '1';
--			end if;
--			
--			if (addr < YCC_RAM_SIZE / 3) then
--			  color := RED_PIXEL;
--			elsif (addr < YCC_RAM_SIZE * 2/3) then
--			  color := GREEN_PIXEL;
--			elsif (addr < YCC_RAM_SIZE) then
--			  color := BLUE_PIXEL;
--			end if;
--			if (ycc_ready = '1') then
--			  ycc_store <= ycc_store_temp;
--			end if;
--			ycc_write_addr <= addr;
--		elsif falling_edge(clk_27) then
--		  buffer_enable <= '1';
--    end if;
--  end process;
  
  buffer_control : process(clk, empty, ycc_ready)
    variable init : std_logic := '1';
    variable addr : natural := 0;
  begin
    if (reset = '0') then
      addr := 0;
      init := '1';
    elsif falling_edge(clk) then
      buffer_latch <= not empty;
      ycc_write_en <= '0';
      bw_buffer_en <= '0';
      if (ycc_ready_latched = '0' and ycc_ready = '1') then
        ycc_store <= ycc_store_temp;
        ycc_write_en <= '1';
        --bw_buffer_en <= '1';
      end if;
      if (ycc_ready_latched = '1' and ycc_ready = '0') then
        bw_buffer_en <= '1';
        addr := addr + 1;
        if (addr = YCC_RAM_SIZE) then
          addr := 0;
        end if;
      end if;
      ycc_ready_latched <= ycc_ready;
      if (init = '1' and ycc_ready = '1') then
        addr := 0;
        init := not init;
      end if;
      ycc_write_addr <= addr;
    end if;
  end process;
  
  fill_bw_buffer : process(clk, reset)
    variable counter : natural := 0;
    variable addr : natural := 0;
    variable bw_buffer : std_logic_vector(BW_BUFFER_WIDTH-1 downto 0);
  begin  
    if (reset = '0') then
      counter := 0;
      addr := 0;
      bw_buffer := (others => '0');
    elsif (rising_edge(clk) and bw_buffer_en = '1') then
      bw_buffer := bw_buffer(SAMPLE_WIDTH-3 downto 0) & filter_result;
      counter := counter + 1;
      bw_write_addr <= addr;
      if (counter = SAMPLE_WIDTH/2) then
        counter := 0;
        addr := addr + 1;
        if (addr = BW_RAM_SIZE) then
          addr := 0;
        end if;
      end if;
      bw_store <= bw_buffer;
    end if;
  end process;
  
end architecture;

