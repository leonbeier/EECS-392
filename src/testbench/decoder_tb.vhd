library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity decoder_tb is
end entity decoder_tb;

architecture test_arch of decoder_tb is
  constant clk_period : time := 37.03703703703 ns;
  
  component adv7180 is
  generic (
    DECIMATION_ROWS : natural := 1;
    DECIMATION_COLS : natural := 1
  );

  port (
    -- tv decoder
    td_clk27 : in std_logic;
    td_data : in std_logic_vector(7 downto 0);
    td_hs, td_vs : in std_logic;
    td_reset : in std_logic;
    
    -- SRAM connections
    ram_clk, ram_we : out std_logic;
    ram_din : out std_logic_vector(31 downto 0);
    ram_write_addr : out natural
  );

  end component adv7180;
  
  component sram is
    generic(
      RAM_SIZE: natural := 128;
      DATA_WIDTH : natural := 32 
    );
    port(
      clk, reset, we: in std_logic;
      write_addr: in natural range 0 to RAM_SIZE-1;
      data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
      read_addr: in natural range 0 to RAM_SIZE-1;
      data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
  end component;

    constant IMAGE_SIZE : natural := 38400;

    -- decoder signals
    signal td_data : std_logic_vector(7 downto 0);
    signal td_clk27, td_hs, td_vs : std_logic;

    -- ram signals
    signal ram_dout : std_logic_vector(31 downto 0);
    signal ram_clk, ram_we : std_logic;
    signal ram_din : std_logic_vector(31 downto 0);
    signal ram_write_addr, ram_read_addr : natural;

    signal reset : std_logic;
    
 begin
  
  -- concurrent signal assignments
  reset <= '1';

  ram_read_addr <= (ram_write_addr - 1) when (ram_read_addr > 0) else 0; 

  sram_map: sram generic map (RAM_SIZE => IMAGE_SIZE, DATA_WIDTH => 32) 
                 port map (td_clk27, reset, ram_we, ram_write_addr, ram_din, ram_read_addr, ram_dout);

  tb_start: adv7180 generic map(DECIMATION_ROWS => 2, DECIMATION_COLS => 2)
                    port map (td_clk27, td_data, td_hs, td_vs, reset, ram_clk, ram_we, ram_din, ram_write_addr);  
  
  clk_process : process is
  begin
       td_clk27 <= '0';
       wait for clk_period/2;  --for 27 mHz /2 signal is '0'.
       td_clk27 <= '1';
       wait for clk_period/2;  --for next 27 mhz /2 signal is '1'.
  end process;
 
  hsync_cycle: process is 
  begin
        td_hs <= '0';
        -- Startup
        wait for 2 * clk_period;
        td_hs <= '1';
        -- H Blank
        wait for 270 * clk_period;  
        -- Active Video
        wait for 1440 * clk_period;
        -- EAV
        wait for 4 * clk_period;
	end process;
  
  vsync_cycle: process is
  begin
        td_vs <= '0';
        --HS to active video time
        wait for 2 * clk_period;
        td_vs <= '1';
        --Length of the image
        wait for (1716 * 263 + 1714) * clk_period;
	end process;
	
	
	data_input: process is
	begin
	  td_data <= x"00";
	  wait for 8 * clk_period;
	  td_data <= x"FF";
    wait for 8 * clk_period;
	end process;
	
end architecture test_arch;
