library IEEE;

use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use WORK.tracker_constants.all;

entity adv7180 is

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

end entity adv7180;


architecture adv7180 of adv7180 is
begin
    
  ram_clk <= td_clk27;
  
  adv7180_decoder: process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    variable clock_count : integer := 0;
    variable ram_address : natural := 0;
  begin
    ram_we <= '0';
    if(rising_edge(td_clk27)) then
      if(clock_count >= 272 and clock_count < 1712) then
        ram_we <= '1';
        ram_din <= td_data;
        ram_address := ram_address + 1;
      end if;
      clock_count := clock_count + 1;
    end if;
    if(rising_edge(td_hs)) then
      clock_count := 0;
    end if;
    if(rising_edge(td_vs)) then
      ram_address := 0;
    end if;
    ram_write_addr <= ram_address;
  end process adv7180_decoder;
  
end architecture adv7180;
