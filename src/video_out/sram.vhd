library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sram is
  generic(
    RAM_SIZE: natural := 128;
    DATA_WIDTH : natural := 32 
  );
  port(
    clk : in std_logic;
    we : in std_logic;
    write_addr : in natural range 0 to RAM_SIZE-1;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    read_addr : in natural range 0 to RAM_SIZE-1;
    data_out : out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity;

architecture behavior of sram is
  type mem is array(0 to RAM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ram_block : mem;
begin
  
  process(clk) is
  begin
    if(rising_edge(clk)) then
      
      data_out <= ram_block(read_addr);
      
      if(we = '1') then
        ram_block(write_addr) <= data_in;
      end if;
      
    end if;
  end process;
  
end architecture behavior;
