library IEEE;

use IEEE.std_logic_1164.all;
use WORK.tracker_constants.all;

entity fifo is
  generic(
    constant BUFFER_SIZE : integer := 100;
    constant DATA_WIDTH : integer := 8
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
    signal empty : out std_logic
  );
end entity fifo;

  
  

  
architecture fifo of fifo is
  signal head : integer := 0;
  signal head_update : integer;
  signal tail : integer := 0;
  signal tail_update : integer;
  signal temp_full : std_logic;
  signal temp_empty : std_logic;

  type buffer_t is array((BUFFER_SIZE) downto 0)  of std_logic_vector((DATA_WIDTH-1) downto 0);
  signal fifo_buffer : buffer_t;
  begin

  buffer_writer: process(write_clk) begin
    if(rising_edge(write_clk)) then
      if(write_en = '1' and temp_full = '0') then
        fifo_buffer(tail) <= data_in;
      end if;
    end if;
  end process buffer_writer;
  
  buffer_tail: process(write_clk, reset) begin
    if(reset = '1') then
      tail <= 0;
    elsif(rising_edge(write_clk)) then
      tail <= tail_update;
    end if;
  end process buffer_tail;

  tail_update <= tail+1 when (write_en = '1' and temp_full = '0' and tail /= BUFFER_SIZE) else
                 0 when (write_en = '1' and temp_full = '0' and tail = BUFFER_SIZE) else
                 tail;
  
  temp_full <= '1' when (tail = BUFFER_SIZE and head = 0) else
	       '1' when (head = tail +1) else
	       '0';

  buffer_reader: process(read_clk) begin
    if(rising_edge(read_clk) and temp_empty /= '1') then
      data_out <= fifo_buffer(head);
    elsif (rising_edge(read_clk)) then
      data_out <= (others => 'U');
    end if;
  end process buffer_reader;

  buffer_head: process(read_clk, reset) begin
    if(reset = '1') then
      head <= 0;
    elsif(rising_edge(read_clk)) then
      head <= head_update;
    end if;
  end process buffer_head;
  
  head_update <= head+1 when (read_en = '1' and temp_empty = '0' and head /= BUFFER_SIZE) else
                 0 when (read_en = '1' and temp_empty = '0' and head = BUFFER_SIZE) else
                 head;
  
  temp_empty <= '0' when (head /= tail) else '1';
  

  full <= temp_full;
  empty <= temp_empty;
end architecture;
