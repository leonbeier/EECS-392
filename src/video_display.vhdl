library IEEE;

use IEEE.std_logic_1164.all;

entity video_display is
  
  port (
    -- fpga clock
    clk_50 : in std_logic;
    
    -- vga
    vga_red, vga_green, vga_blue : out std_logic_vector(9 downto 0);
    vga_hs, vga_vs : out std_logic;
    
    -- adv7180
    td_clk27 : in std_logic;
    td_data : in std_logic_vector(7 downto 0);
    td_hs, td_vs, td_reset : in std_logic
  );
  
end entity video_display;

-- structural design
architecture video_display of video_display is

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

  component adv7180 is

    port (
      -- tv decoder
      td_clk27 : in std_logic;
      td_data : in std_logic_vector(7 downto 0);
      td_hs, td_vs : in std_logic;
      td_reset : in std_logic;

      -- SRAM connections
      ram_clk, ram_we : out std_logic;
      ram_din : out std_logic_vector(7 downto 0);
      ram_write_addr : out natural := 0
    );

  end component adv7180;

  -- ram signals
  signal ram_clk, ram_we : std_logic;
  signal ram_write_addr, ram_read_addr : natural;
  signal ram_din, ram_dout : std_logic_vector(7 downto 0);

begin
  
  ram_read_addr <= 0;

  ram_block: sram generic map(DATA_WIDTH => 8, RAM_SIZE => 2**22-1)
                  port map(ram_clk, ram_we, ram_write_addr, ram_din, ram_read_addr, ram_dout);

  decoder: adv7180 port map(td_clk27, td_data, td_hs, td_vs, td_reset, ram_clk, ram_we, ram_din, ram_write_addr);

end architecture;
