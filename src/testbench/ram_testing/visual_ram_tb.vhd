library ieee;
use ieee.std_logic_1164.all;

entity visual_ram_tb is
end entity;

architecture test of visual_ram_tb is
  
component visual_ram is
  port(
    clk : in std_logic;
    reset : in std_logic;
    
    led0 : out std_logic_vector(6 downto 0);
    led1 : out std_logic_vector(6 downto 0);
    led2 : out std_logic_vector(6 downto 0);
    led3 : out std_logic_vector(6 downto 0)
  );
end component;

signal clk, reset : std_logic;
signal led0, led1, led2, led3 : std_logic_vector(6 downto 0);

begin
  
    test_ram : visual_ram port map(clk, reset, led0, led1, led2, led3);
  
  process
  begin
    
    clk <= '1';
    reset <= '1';
    wait for 5 ns;
    clk <= '0';
    wait for 5 ns;
    reset <= '0';
  
    for i in 1 to 200000 loop
      clk <= '1';
      wait for 5 ns;
      clk <= '0';
      wait for 5 ns;
    end loop;
    
    wait for 5 ns;
    wait;
  
  end process;
  
end architecture;






