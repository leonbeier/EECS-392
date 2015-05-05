library IEEE;

use IEEE.std_logic_1164.all;

entity adv7180_decoder

  generic (
    
  )

  port (
    -- tv decoder
    td_data : in std_logic_vector(7 downto 0);
    td_clk27, td_hs, td_vs : in std_logic;
    td_reset_n : in std_logic;
    
    -- clocks
    clock_50 : in std_logic;
    
    -- vga
    vga_red, vga_green, vga_blue : out std_logic_vector(9 downto 0);
    vga_hs, vga_vs, vga_blank, vga_clk : out std_logic;
    
    -- SRAM
    sdram_clk, sdram_we : out std_logic;
    sdram_data_out, sdram_data_in : out std_logic_vector(31 downto 0);
  )

end entity adv7180_decoder;

architecture adv7180_decoder of adv7180_decoder is
begin
  
end architecture adv7180_decoder;
