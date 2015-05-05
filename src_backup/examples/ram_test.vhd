library IEEE;
use IEEE.std_logic_1164.all;
use work.constants.all;
use ieee.numeric_std.all;

entity ram_test is
	port(
		clk : in std_logic;
		
		read_disp : out std_logic_vector(6 downto 0);
		write_disp : out std_logic_vector(6 downto 0)
	);
end entity ram_test;

architecture struct of ram_test is

component sdram is
  generic(
    address_count: natural
  );
  port(
    clk: in std_logic;
    data: in std_logic_vector(DATA_WIDTH-1 downto 0);
    write_addr: in natural range 0 to address_count-1;
    read_addr: in natural range 0 to address_count-1;
    we: in std_logic;
    res: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component sdram;

component leddcd is
	port(
		 data_in : in std_logic_vector(3 downto 0);
		 segments_out : out std_logic_vector(6 downto 0)
		);
end component leddcd;

constant RAM_SIZE : natural := 5;

signal data : std_logic_vector(DATA_WIDTH-1 downto 0);
signal write_addr : natural;
signal read_addr : natural;
signal res : std_logic_vector(DATA_WIDTH-1 downto 0);

begin

	ram : sdram 
		generic map(RAM_SIZE) 
		port map(
		clk => clk, 
		data => data, 
		write_addr => 
		write_addr, 
		read_addr => read_addr, 
		we => '1', 
		res => res);
	
	process(clk)
	
	variable counter : natural := 0;
	variable w_addr : natural := 2;
	variable r_addr : natural := 0;
	variable d : natural := 0;
	
	begin
		if falling_edge(clk) then
			counter := counter + 1;
			if (counter = 25000000) then
				counter := 0;
				
				d := d + 1;
				if (d > 9) then
					d := 0;
				end if;
				
				w_addr := w_addr + 1;
				if (w_addr > RAM_SIZE-1) then
					w_addr := 0;
				end if;
				
				r_addr := r_addr + 1;
				if (r_addr > RAM_SIZE-1) then
					r_addr := 0;
				end if;
				
			end if;
		end if;
		
		data <= std_logic_vector(to_unsigned(d, DATA_WIDTH));
		write_addr <= w_addr;
		read_addr <= r_addr;
	
	end process;
	
	led_r : leddcd port map(data_in => data(3 downto 0), segments_out => read_disp);
	led_w : leddcd port map(data_in => res(3 downto 0), segments_out => write_disp);

end architecture struct;