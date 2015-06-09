library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity visual_ram is
  port(
    clk : in std_logic;
    reset : in std_logic;
    
    led0 : out std_logic_vector(6 downto 0);
    led1 : out std_logic_vector(6 downto 0);
    led2 : out std_logic_vector(6 downto 0);
    led3 : out std_logic_vector(6 downto 0)
  );
end entity;

architecture structural of visual_ram is
  
component sdram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk: in std_logic;
    we : in std_logic;
	  re : in std_logic;
    write_addr: in natural range 0 to RAM_SIZE-1;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr: in natural range 0 to RAM_SIZE-1;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component;

component sram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk: in std_logic;
    we : in std_logic;
    write_addr: in natural range 0 to RAM_SIZE-1;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr: in natural range 0 to RAM_SIZE-1;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end component;

component leddcd is
	port(
		 data_in : in std_logic_vector(3 downto 0);
		 segments_out : out std_logic_vector(6 downto 0)
		);
end component;	
  
  constant RAM_SIZE : natural := 240 * 320 / 2;
  signal write_addr, read_addr : natural;
  signal data_in, data_out : std_logic_vector(31 downto 0);
  signal data : std_logic_vector(31 downto 0);
  
begin
  
  mem : sram
  generic map(
    RAM_SIZE => RAM_SIZE,
    DATA_WIDTH => 32
  )
  port map(
    clk => clk,
    we => '1',
    write_addr => write_addr,
    data_in => data_in,
    read_addr => read_addr,
    data_out => data_out
  );
  
  write_ram : process(clk, reset)
	  variable addr : natural := 0;
  begin
    if (reset = '1') then
      addr := 0;		
    elsif rising_edge(clk) then
      addr := addr + 1;
		  if (addr >= RAM_SIZE) then
		  	addr := 0;
		  end if;
      write_addr <= addr;
      data_in <= std_logic_vector(to_signed(addr, 32));
    end if;
  end process;
  
  read_ram : process(clk, reset)
	  variable addr : natural := 0;
	  variable cycles : natural := 0;
  begin
    if (reset = '0') then
      addr := 0;		
      cycles := 0;
    elsif rising_edge(clk) then
      cycles := cycles + 1;
      if (cycles >= 50000000) then
        cycles := 0;
        addr := addr + 1;
		    if (addr >= RAM_SIZE) then
		  	   addr := 0;
		    end if;
		  end if;
      read_addr <= addr;
		data <= std_logic_vector(to_signed(read_addr, 32));
    end if;
  end process;

  disp0 : leddcd port map(data_in => data_out(3 downto 0), segments_out => led0);
  disp1 : leddcd port map(data_in => data_out(7 downto 4), segments_out => led1);
  disp2 : leddcd port map(data_in => data_out(11 downto 8), segments_out => led2);
  disp3 : leddcd port map(data_in => data_out(15 downto 12), segments_out => led3);
  
end architecture;