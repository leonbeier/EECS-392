library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.math_real.all;

entity adv7180

  port (
    -- tv decoder
    td_data : in std_logic_vector(7 downto 0);
    td_clk27, td_hs, td_vs : in std_logic;
    td_reset_n : in std_logic;
    
    -- clocks
    clock_50 : in std_logic;
    
    -- SRAM
    sdram_clk, sdram_we : out std_logic;
    sdram_data_out, sdram_data_in : out std_logic_vector(31 downto 0);
  )

end entity adv7180;


architecture adv7180 of adv7180 is
  component sdram is
    generic(
      RAM_SIZE: natural := 32;
      DATA_WIDTH : natural := 32
    );
    
    port(
      clk: in std_logic;
      data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
      write_addr: in natural range 0 to RAM_SIZE-1;
      read_addr: in natural range 0 to RAM_SIZE-1;
      we: in std_logic;
      data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
    ); 
  end component sdram;
  
  signal ram_clk, ram_we : std_logic;
  signal ram_dout : std_logic_vector(IMAGE_DEPTH-1 downto 0);
  signal ram_write_addr, ram_read_addr : std_logic_vector(ceil(log2(real(IMAGE_WIDTH*IMAGE_HEIGHT)))-1 downto 0);
  signal image_data : std_logic_vector(7 downot 0);
  signal ram_size : integer := integer(ceil(log2(real(IMAGE_WIDTH*IMAGE_HEIGHT))));
begin
  -- index each pixel using single line ram buffer
  ram_buffer: sdram generic map(RAM_SIZE => ram_size, 
                                DATA_WIDTH => IMAGE_DEPTH)
                    port map(clk => td_clk27, 
                             data_in => image_data, 
                             write_addr => ram_write_addr, 
                             read_addr => ram_read_addr, 
                             we => ram_we, 
                             data_out => ram_dout);
  
  adv7180_decoder: process is
    variable clock_count : integer := 0;
    
    -- array of 4 elements
    variable pixel_buffer : integer_buffer;
  begin
    ram_we <= '0';
    if(rising_edge(td_vs)) then
      ram_write_addr <= 0;
    elsif(rising_edge(td_hs)) then
      clock_count := 0;
    elsif(rising_egde(td_clk27)) then
      if(clock_count >= 272 and clock_count < 1712) then
        ram_we <= '1';
        image_data <= td_data;
        ram_write_addr <= ram_write_addr + 1;
      end if;
      clock_count := clock_count + 1;
    end if;
  end process adv7180;
  
end architecture adv7180;
