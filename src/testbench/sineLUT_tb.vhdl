library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity sineLUT_tb is
  generic map(
    DECIMAL_WIDTH := 32,
    FRACTION_WIDTH := 20;
  );
    
  port map(

  );
end entity sineLUT_tb;

architecture sineLUT_tb of sineLUT_tb is
	
  signal latch : std_logic := '0';
  signal radians : sfixed();
  signal sine : sfixed();
  
begin
  
  sineLUT_test: sineLUT port map(latch, radians, sine);
  
	test: process 
  begin
    
    latch <= '0';
    wait for 5 ns;
    latch <= '1';
    wait for 5 ns;
    
    latch <= '0';
    wait for 5 ns;
    latch <= '1';
    wait for 5 ns;
    
    latch <= '0';
    wait for 5 ns;
    latch <= '1';
    wait for 5 ns;
    
    latch <= '0';
    wait for 5 ns;
    latch <= '1';
    wait for 5 ns;
    -- data_in <= "00001000";
    -- wait for 5 ns;
    -- write_clk <= '1';
    -- wait for 5 ns;
    -- read_clk <= '1';
    -- wait for 5 ns;
    wait;
	end process;
  
end architecture;











