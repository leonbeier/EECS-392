library ieee;
use ieee.std_logic_1164.all;

entity vga_ram_tb is
end entity;

architecture test of vga_ram_tb is
  
component VGA_RAM is
  port (
    clk, reset : in std_logic
  );
end component VGA_RAM; 

signal clk, reset : std_logic;

begin
  
    test_mod : vga_ram port map(clk, reset);
  
  process
  begin
    
    clk <= '1';
    reset <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    reset <= '0';
  
    for i in 1 to 310000 loop
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
    
    wait for 5 ns;
    wait;
  
  end process;
  
end architecture;
