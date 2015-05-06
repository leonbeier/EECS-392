library ieee;
use ieee.std_logic_1164.all;
use work.constants.all;
use ieee.numeric_std.all;

entity sdram is
  generic(
    RAM_SIZE: natural := 32;
    DATA_WIDTH : natural := 32; 
  );
  port(
    clk: in std_logic;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    write_addr: in natural range 0 to RAM_SIZE-1;
    read_addr: in natural range 0 to RAM_SIZE-1;
    we: in std_logic;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
end entity sdram;

architecture behavior of sdram is
  type mem is array(0 to RAM_SIZE-1) of std_logic_vector(DATA_WIDTH-1 downto 0);
  signal ram_block : mem;
begin
  
  process(clk)
  begin
        if (falling_edge(clk)) then
          if (we = '1') then
            ram_block(write_addr) <= data_in;
          end if;
          data_out <= ram_block(read_addr);
        end if;
  end process;
  
end architecture behavior;
