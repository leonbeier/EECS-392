library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity video_out_tb is
end entity;

architecture test of video_out_tb is
  
component video_out is
	port(
			clk : in std_logic;
			clk_27 : in std_logic;
			reset : in std_logic;
			
			--VGA 
			red, green, blue : out std_logic_vector(7 downto 0); 
			h_sync, v_sync, blank, vga_clk	: out std_logic
			
		);
end component video_out;

signal clk, clk_27 : std_logic;
signal reset : std_logic; 
signal red, green, blue : std_logic_vector(7 downto 0); 
signal h_sync, v_sync, blank, vga_clk	: std_logic;

constant CLK_FRQ : natural := 50000000;
constant CLK_PER : time := 1 sec / CLK_FRQ;
constant half_period : time := CLK_PER / 2;
constant CLK_FRQ_27 : natural := 27000000;
constant CLK_PER_27 : time := 1 sec / CLK_FRQ_27;
constant half_period_27 : time := CLK_PER_27 / 2;

constant CYCLE_MAX : natural := 4000000;
signal done : std_logic := '0';

begin
  
    test_video : video_out port map(clk, clk_27, reset, red, green, blue, h_sync, v_sync, blank, vga_clk);

  process
  begin
      reset <= '0';
      wait for CLK_PER_27;
      reset <= '1';
      wait;
  end process;

  process
  begin
    
    clk <= '1';
    wait for half_period;
    clk <= '0';
    wait for half_period;
  
    for i in 1 to CYCLE_MAX loop
      clk <= not clk;
      wait for half_period;
      clk <= not clk;
      wait for half_period;
    end loop;
    
    done <= '1';
    
    wait for half_period;
    wait;
  
  end process;
  
  process
  begin
    
    if (done = '1') then
      wait;
    end if;
    
    clk_27 <= '1';
    wait for half_period_27;
    clk_27 <= '0';
    wait for half_period_27;
  
  end process;
  
end architecture;




