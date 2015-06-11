-- Quartus II VHDL Template
-- Simple Dual-Port RAM with different read/write addresses and
-- different read/write clock

library ieee;
use ieee.std_logic_1164.all;

entity dual_port_ram is
	generic 
	(
		DATA_WIDTH : natural := 32;
		RAM_SIZE : natural := 128
	);
	port 
	(
		rclk	: in std_logic;
		wclk	: in std_logic;
		read_addr	: in natural range 0 to RAM_SIZE-1;
		write_addr	: in natural range 0 to RAM_SIZE-1;
		we		: in std_logic := '1';
		data_in	: in std_logic_vector((DATA_WIDTH-1) downto 0);
		data_out	: out std_logic_vector((DATA_WIDTH -1) downto 0)
	);
end dual_port_ram;

architecture rtl of dual_port_ram is

	-- Build a 2-D array type for the RAM
	subtype word_t is std_logic_vector((DATA_WIDTH-1) downto 0);
	type memory_t is array(0 to RAM_SIZE-1) of word_t;

	-- Declare the RAM signal.	
	signal ram : memory_t;

begin

	process(wclk)
	begin
	if(rising_edge(wclk)) then 
		if(we = '1') then
			ram(write_addr) <= data_in;
		end if;
	end if;
	end process;

	process(rclk)
	begin
	if(rising_edge(rclk)) then 
		data_out <= ram(read_addr);
	end if;
	end process;

end rtl;

