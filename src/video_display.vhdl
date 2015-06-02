library IEEE;

use IEEE.std_logic_1164.all;

entity video_display
  
  port (
    clk_50
    
    -- vga
    vga_red, vga_green, vga_blue : out std_logic_vector(9 downto 0);
    vga_hs, vga_hs : out std_logic
    
    -- adv7180
    td_clk27 : out std_logic;
    td_data : out std_logic_vector(7 downto 0);
    td_hs, td_vs, td_reset : out std_logic;
  );
  
end entity video_display;

-- structural design
architecture video_display of video_display is

begin

  decoder: adv7180 
    port map(td_clk27, td_data, td_hs, td_vs, td_reset, ram_clk, ram_we, ram_din, ram_write_addr);
  
  -- vga :

end architecture;
