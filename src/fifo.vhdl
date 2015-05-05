library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity fifo is
  generic(
    constant BUFFER_SIZE : natural := 100;
    constant DATA_WIDTH : natural := 8
  );
  
  port(
    signal read_clk : in std_logic;
    signal write_clk : in std_logic;
    signal reset : in std_logic;
    signal read_en : in std_logic;
    signal write_en : in std_logic;
    signal data_in : in std_logic_vector((DATA_WIDTH-1) downto 0);
    signal data_out : out std_logic_vector((DATA_WIDTH-1) downto 0);
    signal full : out std_logic;
    signal empty : out std_logic;
  );
end entity fifo;
  signal head : natural := 0;
  signal head_update : natural;
  signal tail : natural := 0;
  signal tail_update : natural;
  
  type buffer_t is array((BUFFER_SIZE-1) downto 0)  of std_logic_vector((DATA_WIDTH-1) downto 0);
  signal fifo_buffer : buffer_t;
architecture fifo of fifo is

  buffer_writer: process(write_clk) begin
    if(rising_edge(write_clk)) then
      if(write_en = '1' and full = '0') then
        fifo_buffer(tail) <= data_in;
      end if;
    end if;
  end process buffer_writer;
  
  buffer_tail process(write_clk, reset) begin
    if(reset = '1') then
      tail <= 0;
    elsif(rising_edge(write_clk)) then
      tail <= tail_update;
    end if;
  end process buffer_tail;
  
  tail_update <= tail+1 when (write_en = '1' and full = '0' and tail /= BUFFER_SIZE-1) else
                 0 when (write_en = '1' and full = '0' and tail = BUFFER_SIZE-1) else
                 tail;
  
  full <= '0' when (head < BUFFER_SIZE-2 and head /= tail+2) else
          '0' when (head = BUFFER_SIZE-2 and head /= 0) else
          '0' when (head = BUFFER_SIZE-1 and head /= 1) else
          '1';
  
  buffer_reader: process(read_clk) ebgin
    if(rising_edge(read_clk) then
      data_out <= fifo_buffer(head);
    end if;
  end process buffer_reader;

  buffer_head: process(read_clk, reset) begin
    if(reset = '1') then
      head <= 0;
    elsif(rising_edge(read_clk)) then
      head <= head_update;
    end if;
  end process buffer_head;
  
  head_update <= head+1 when (read_en = '1' and empty = '0' and head /= BUFFER_SIZE-1) else
                 0 when (read_en = '1' and empty = '0' and head = BUFFER_SIZE-1) else
                 head;
  
  empty <= '0' when (head /= tail) else '1';
 
end architecture;
