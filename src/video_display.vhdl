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
    td_reset : out std_logic;
    
    -- i2c -------------------------------------------------------------------------
    i2c_clk, i2c_data : inout std_logic;
    i2c_error : out std_logic;
    i2c_config_clk : in std_logic;
    i2c_status_led : out std_logic;
	 i2c_availability : out std_logic;
    
    -- TESTING -------------------------------------------------------------------------
    segments_out : out std_logic_vector(6 downto 0);
    i2c_state_segments : out std_logic_vector(6 downto 0);
    reset_led : out std_logic;
	 
	 gpio_i2c_clk : inout std_logic;
	 gpio_i2c_data : inout std_logic
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

  component i2c is
    generic (
      FREQUENCY : natural := 12_500_000 --10,000
    );

    port (
      -- clocks
      clock_50 : in std_logic;
      reset : in std_logic;
      error : out std_logic;

      -- i2c communications
      sda : inout std_logic;
      scl : inout std_logic;
      data_clk : in std_logic;
      data_addr : in std_logic_vector(I2C_ADDR_WIDTH-1 downto 0);
      data_in : in std_logic_vector(I2C_DATA_WIDTH-1 downto 0);
      write_en, read_en : in std_logic; -- writing takes prescedence over reading
      available : out std_logic;

      -- fifo control
      write : in std_logic;
      odata : out std_logic_vector(7 downto 0);
      idata : in std_logic_vector(7 downto 0)
    );
  end component i2c;
  
  -- constants
  constant IMAGE_SIZE : natural := 38400;
  
  -- fifo signals -------------------------------------------------------------------------
  signal fifo_read_clk, fifo_write_clk, fifo_read_en, fifo_write_en : std_logic;
  signal fifo_din, fifo_dout : std_logic_vector(7 downto 0);
  signal fifo_full, fifo_empty : std_logic;

  -- i2c signals -------------------------------------------------------------------------
  signal i2c_write_en, i2c_read_en, i2c_available, i2c_data_clk : std_logic;
  signal i2c_daddr : std_logic_vector(I2C_ADDR_WIDTH-1 downto 0);
  signal i2c_write : std_logic;
  signal i2c_din, i2c_dout : std_logic_vector(I2C_DATA_WIDTH-1 downto 0);
  type config_state is (INIT_CONFIG, I2C_ADDR_CONFIG, I2C_DATA_CONFIG, DONE_CONFIG);
  signal i2c_config_state : config_state;

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
  
  -- TESTING -------------------------------------------------------------------------
  signal led_count : std_logic_vector(3 downto 0);
  signal i2c_state_count : std_logic_vector(3 downto 0);
  
  component leddcd is
    port(
		  data_in : in std_logic_vector(3 downto 0);
		  segments_out : out std_logic_vector(6 downto 0)
    );
  end component leddcd;

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

  i2c_write <= '1';
  
  -- structural port maps -------------------------------------------------------------------------
  ram_block: sram generic map(DATA_WIDTH => 32, RAM_SIZE => IMAGE_SIZE)
                  port map(ram_clk, reset, ram_we, ram_write_addr, ram_din, ram_read_addr, ram_dout);
  
  decoder: adv7180 generic map(DECIMATION_ROWS => 1, DECIMATION_COLS => 1)
                   port map(td_clk27, td_data, td_hs, td_vs, reset, ram_clk, ram_we, ram_din, ram_write_addr);
  
  ycc2rgb_converter: ycc2rgb port map(ycc_clk, reset, ycc_y, ycc_cb, ycc_cr, red_out, green_out, blue_out);
  
  vga_output: vga port map(clk50, reset, vga_pixel, vga_pixel_clk, vga_pixel_row, vga_pixel_col, vga_hs, vga_vs, vga_blank, vga_red, vga_green, vga_blue);

  fifo_i2c: fifo port map(fifo_read_clk, fifo_write_clk, reset, fifo_read_en, fifo_write_en, fifo_din, fifo_dout, fifo_full, fifo_empty);

  i2c_master: i2c generic map(FREQUENCY => 100_000)
                  port map(clk50, reset, i2c_error, i2c_data, i2c_clk, i2c_data_clk, i2c_daddr, i2c_din, 
                           i2c_write_en, i2c_read_en, i2c_available, i2c_write, fifo_din, i2c_dout);
  
  -- ram address update -------------------------------------------------------------------------
  ram_read_manager: process(vga_pixel_clk, reset) is
  begin
    if(reset = '0') then
      -- active low reset
      ram_read_addr <= 0;
      ycc_even <= true;
    elsif(falling_edge(vga_pixel_clk)) then
      ram_read_addr <= ((vga_row_int * IMAGE_WIDTH) + vga_col_int)/2;
      case(ram_read_addr mod 2) is
        when 1 => ycc_even <= false;
        when others => ycc_even <= true;
      end case;
      vga_pixel <= red_out & green_out & blue_out;
    end if;
  end process;

  -- decoder configuration -------------------------------------------------------------------------\
  decoder_config: process(i2c_clk, i2c_data) is
  begin
    if(reset = '0') then
      i2c_data_clk <= '0';
      i2c_config_state <= INIT_CONFIG;
      i2c_status_led <= '0';
    elsif(falling_edge(clk50)) then
      case(i2c_config_state) is
        when INIT_CONFIG =>
          i2c_status_led <= '0';
          i2c_write_en <= '0';
          i2c_read_en <= '0';
          i2c_daddr <= std_logic_vector(to_unsigned(16#30#, 7));
			
          -- i2c_config_state <= I2C_ADDR_CONFIG;
        when I2C_ADDR_CONFIG =>
			 i2c_write_en <= '1';
			 i2c_din <= "00000000";
          if(i2c_available ='0') then
				i2c_write_en <= '0';
            i2c_config_state <= I2C_DATA_CONFIG;
          end if;
        when I2C_DATA_CONFIG =>
			 i2c_write_en <= '1';
			 i2c_din <= "01010000";    -- configured for composite input on Ain1 and NTSC M
          if(i2c_available = '0') then
				i2c_write_en <= '0';
            i2c_config_state <= DONE_CONFIG;
          end if;
        when DONE_CONFIG =>
          i2c_status_led <= '1';
          i2c_config_state <= INIT_CONFIG;
        when others =>
          i2c_config_state <= INIT_CONFIG;
      end case;
    end if;
  end process;
  
  -- TESTING -------------------------------------------------------------------------
  decoder_clock: process(td_clk27) is
    variable clock_count : natural := 0;
    variable decimation : natural := 27000000;
  begin
    if(reset = '0') then
      clock_count := 0;
      led_count <= std_logic_vector(to_unsigned(0, 4));
    elsif(rising_edge(td_clk27)) then
      clock_count := clock_count + 1;
      if(clock_count = decimation) then
        clock_count := 0;
        led_count <= std_logic_vector(unsigned(led_count) + 1);
      end if;
    end if;
  end process;
  
  gpio_i2c_clk <= i2c_clk;
  gpio_i2c_data <= i2c_data;
  
  i2c_state_count <= "0000" when (i2c_config_state = INIT_CONFIG) else
                     "0001" when (i2c_config_state = I2C_ADDR_CONFIG) else
                     "0010" when (i2c_config_state = I2C_DATA_CONFIG) else
                     "0011" when (i2c_config_state = DONE_CONFIG) else
                     "0100";

  led_output: leddcd port map(led_count, segments_out);
  i2c_state_output : leddcd port map(i2c_state_count, i2c_state_segments);
  
  reset_led <= reset;
  
end architecture;
