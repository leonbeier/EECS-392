library IEEE;

use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use WORK.tracker_constants.all;

entity adv7180 is

  port (
    -- tv decoder
    td_clk27 : in std_logic;
    td_data : in std_logic_vector(7 downto 0);
    td_hs, td_vs : in std_logic;
    td_reset : in std_logic;
    
    -- SRAM connections
    ram_clk, ram_we : out std_logic;
    ram_din : out std_logic_vector(7 downto 0);
    ram_write_addr : out natural := 0
  );

end entity adv7180;

architecture adv7180 of adv7180 is

  component fifo is
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
      signal empty : out std_logic
    );
  end component fifo;
  
  -- shared variables
  signal state : decoder_state;
  signal next_state : decoder_state;
  signal data_address : natural;
  signal vs_flag, hs_flag : std_logic;
  
  -- FIFO Signals
  -- signal fifo_read_clk, fifo_write_clk, fifo_reset, 
  --       fifo_read_en, fifo_write_en, fifo_full, fifo_empty : std_logic;
  -- signal fifo_din, fifo_dout : std_logic_vector(7 downto 0);

begin
    
  -- data_fifo: fifo generic map(DATA_WIDTH => 8, BUFFER_SIZE => 2**22-1) 
  --                 port map(fifo_read_clk, fifo_write_clk, fifo_reset, fifo_read_en, fifo_write_en, fifo_din, fifo_dout, fifo_full, fifo_empty);
  -- fifo_read_clk <= clk50;
  -- fifo_write_clk <= clk50;
  -- fifo_reset <= td_reset;
  ram_clk <= td_clk27;
  
  adv7180_decoder: process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    variable clock_count : integer := 0;
    variable ram_address : natural := 0;
  begin
    if(td_reset = '0') then
      state <= VS_RESET;
    elsif(rising_edge(td_clk27)) then
      case(state) is
        when VS_RESET | HS_RESET =>
          if(state = VS_RESET) then
            ram_address := 0;
          end if;
          ram_we <= '0';
          clock_count := 0;
          state <= READ;
        when READ =>
          if(vs_flag = '1') then
            state <= VS_RESET;
          elsif(hs_flag = '1') then
            state <= HS_RESET;
          else
            if(clock_count >= 272 and clock_count < 1712) then
              ram_we <= '1';
              ram_din <= td_data;
              ram_address := ram_address + 1;
            else
              ram_we <= '0';
            end if;
            clock_count := clock_count + 1;
          end if;
    end if;
    data_address <= ram_address;
  end process adv7180_decoder;
  
  hs_manager:  process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    variable hs_idle : boolean := true;
  begin
    if(td_reset = '0') then
      hs_idle := true;
      hs_flag <= '0';
    elsif(rising_edge(td_clk27)) then
      hs_flag <= '0';
      if(hs_idle) then
        if(td_hs = '1') then
          hs_flag <= '1';
          hs_idle := false;
        end if;
      else
        if(td_hs = '0') then
          hs_idle := true;
        end if;
      end if;
    end if;
  end process hs_manager;
  
  vs_manager: process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    variable vs_idle : boolean := true;
  begin
    if(td_reset = '0') then
      vs_idle := true;
      vs_flag <= '0';
    elsif(rising_edge(td_clk27)) then
      vs_flag <= '0';
      if(vs_idle) then
        if(td_vs = '1') then
          vs_flag <= '1';
          vs_idle := false;
        end if;
      else
        if(td_vs = '0') then
          vs_idle := true;
        end if;
      end if;
    end if;
  end process vs_manager;

end architecture adv7180;
