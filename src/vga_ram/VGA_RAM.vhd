library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_RAM is
  port (
    clk, reset : in std_logic
  );
end entity VGA_RAM;

architecture structural of VGA_RAM is

  constant IMG_WIDTH : natural := 320;
  constant IMG_HEIGHT : natural := 240;
  constant DATA_WIDTH : natural := 32;
  constant RAM_SIZE : natural := IMG_WIDTH * IMG_HEIGHT;
  
  signal row, col : natural;
  signal read_addr : natural;
  signal pixel : std_logic_vector(DATA_WIDTH-1 downto 0);
  signal cs_vector : std_logic_vector(3 downto 0);
  signal img_sel : std_logic_vector(1 downto 0);
  
  signal write_addr : natural;
  signal color0, color1, color2, color3 : std_logic_vector(DATA_WIDTH-1 downto 0);
  
  signal red, green, blue : std_logic_vector(7 downto 0);
  signal h_sync, v_sync : std_logic;
  signal blank, vga_clk : std_logic;
  
  signal pixel0, pixel1, pixel2, pixel3 : std_logic_vector(DATA_WIDTH-1 downto 0);

component sdram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk: in std_logic;
    cs: in std_logic;
    we: in std_logic;
    write_addr: in natural range 0 to RAM_SIZE-1;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr: in natural range 0 to RAM_SIZE-1;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component sdram;

component VGA is
  generic(
    HORI_SCREENS : natural := 2;
    VERT_SCREENS : natural := 2
  );
	port(
			clk    : in std_logic;
			reset  : in std_logic;
			pixel  : in std_logic_vector(31 downto 0);
	
			--VGA 
			red, green, blue 					          : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk		: out std_logic;
			
			img_sel  : out std_logic_vector(1 downto 0);
			row      : out natural;
			col      : out natural
		);
end component VGA;

begin
  rgb_left : sdram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => DATA_WIDTH
  ) 
  port map(
    clk => clk,
    cs => cs_vector(0),
    we => '1',
    write_addr => write_addr,
    data_in => color0,
    read_addr => read_addr,
    data_out => pixel0
  );
  
  rgb_right : sdram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => DATA_WIDTH
  ) 
  port map(
    clk => clk,
    cs => cs_vector(1),
    we => '1',
    write_addr => write_addr,
    data_in => color1,
    read_addr => read_addr,
    data_out => pixel1
  );
  
  bw_left : sdram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => DATA_WIDTH
  ) 
  port map(
    clk => clk,
    cs => cs_vector(2),
    we => '1',
    write_addr => write_addr,
    data_in => color2,
    read_addr => read_addr,
    data_out => pixel2
  );
  
  bw_right  : sdram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => DATA_WIDTH
  ) 
  port map(
    clk => clk,
    cs => cs_vector(3),
    we => '1',
    write_addr => write_addr,
    data_in => color3,
    read_addr => read_addr,
    data_out => pixel3
  );
  
  vga_mod : VGA 
  port map(
    clk => clk, 
    reset => reset, 
    pixel => pixel, 
    red => red, 
    green => green, 
    blue => blue, 
    h_sync => h_sync, 
    v_sync => v_sync, 
    blank => blank, 
    vga_clk => vga_clk, 
    img_sel => img_sel, 
    row => row, 
    col => col
  );
  
  read_addr <= row * IMG_WIDTH + col;
  
  -- decode image select for use as RAM chip select
  with img_sel select cs_vector <=
    "0001" when "00",
    "0010" when "01",
    "0100" when "10",
    "1000" when "11",
    "0000" when others;
    
  with img_sel select pixel <=
    pixel0 when "00",
    pixel1 when "01",
    pixel2 when "10",
    pixel3 when "11",
    (others => '0') when others;
    
  write_ram : process(clk, reset)
    variable counter : natural;
    variable addr : natural;
    constant COLOR_WIDTH : natural := DATA_WIDTH - 8;
    variable c0 : std_logic_vector(COLOR_WIDTH-1 downto 0);
    variable c1 : std_logic_vector(COLOR_WIDTH-1 downto 0);
    variable c2 : std_logic_vector(COLOR_WIDTH-1 downto 0);
    variable c3 : std_logic_vector(COLOR_WIDTH-1 downto 0);
  begin
    if (reset = '1') then
      counter := 0;
      addr := 0;
      c0 := x"FF0000";
      c1 := x"00FF00";
      c2 := x"0000FF";
      c3 := x"FF00FF";
      
    elsif falling_edge(clk) then
      addr := addr + 1;
      counter := counter + 1;
      
      if (addr = RAM_SIZE) then
        addr := 0;
      end if;
      if (counter = 100000000) then
        counter := 0;
        c0 := c0(COLOR_WIDTH-9 downto 0) & c0(COLOR_WIDTH-1 downto COLOR_WIDTH-8);
        c1 := c1(COLOR_WIDTH-9 downto 0) & c1(COLOR_WIDTH-1 downto COLOR_WIDTH-8);
        c2 := c2(COLOR_WIDTH-9 downto 0) & c2(COLOR_WIDTH-1 downto COLOR_WIDTH-8);
        c3 := c3(COLOR_WIDTH-9 downto 0) & c3(COLOR_WIDTH-1 downto COLOR_WIDTH-8);
      end if;        
      
      write_addr <= addr;
    end if;
    
    color0 <= x"00" & c0;
    color1 <= x"00" & c1;
    color2 <= x"00" & c2;
    color3 <= x"00" & c3;
  end process;

end architecture structural;



