library IEEE;

use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;
use WORK.tracker_constants.all;

entity adv7180 is
  
  generic (
    -- vertical and horizontal pixel decimation
    DECIMATION_ROWS : natural := 1;
    DECIMATION_COLS : natural := 1
  );

  port (
    -- tv decoder
    td_clk27 : in std_logic;
    td_data : in std_logic_vector(7 downto 0);
    td_hs, td_vs : in std_logic;
    td_reset : in std_logic;
    
    -- SRAM connections
    ram_clk, ram_we : out std_logic;
    ram_din : out std_logic_vector(31 downto 0);
    ram_write_addr : out natural
  );

end entity adv7180;

architecture adv7180 of adv7180 is

  -- constants
  constant IMAGE_SIZE : natural := 38400;
  
  -- shared variables
  signal state : decoder_state;
  signal data_address : natural;
  signal vs_flag, hs_flag : std_logic;

begin
    
  ram_clk <= not td_clk27;
  ram_write_addr <= data_address;
  
  adv7180_decoder: process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    variable clock_count : natural := 0;
    variable decimation_count_cols : natural := 0;
    variable decimation_count_rows : natural := 0;
    variable next_data_address : natural := 0;
    variable buffer_index : natural := 0;
    variable data_buffer : std_logic_vector(31 downto 0);
  begin
    if(td_reset = '0') then
      state <= VS_RESET;
    elsif(rising_edge(td_clk27)) then
      case(state) is
        when VS_RESET | HS_RESET =>
          -- HS_RESET and VS_RESET
          ram_we <= '0';
          buffer_index := 0;
          data_buffer := (others => '0');
          clock_count := 5;

          -- HS_RESET has a lower priority
          decimation_count_cols := 0;
          if(decimation_count_rows = (DECIMATION_ROWS-1)) then
            decimation_count_rows := 0;
          else
            decimation_count_rows := decimation_count_rows + 1;
          end if;

          -- VS_RESET has a higher priority
          if(state = VS_RESET) then
            decimation_count_rows := 0;
            next_data_address := 0;
            data_address <= 0;
          end if;

          -- Update the state
          state <= READ;
        when READ =>
          if(vs_flag = '1') then
            -- Restart the image buffering
            state <= VS_RESET;
          elsif(hs_flag = '1') then
            -- Progress to th next row
            state <= HS_RESET;
          else
            -- Don't write by default
            ram_we <= '0';
            if(decimation_count_rows = (DECIMATION_ROWS-1)) then
              if(clock_count >= 272 and clock_count < 1712) then
                -- ACTIVE VIDEO
                -- Update the data buffer using the current index
                data_buffer(8*(buffer_index+1)-1 downto 8*buffer_index) := td_data;
                if(buffer_index = 3) then
                  -- Roll over the data buffer index
                  buffer_index := 0;
                  if(decimation_count_cols = (DECIMATION_COLS-1)) then
                    -- Roll over the column-wise decimation counter
                    decimation_count_cols := 0;
                    if(data_address <= IMAGE_SIZE) then
                      -- Write at the next rising edge
                      ram_we <= '1';
                      ram_din <= data_buffer;
                      -- Delay a write into the SRAM by one clock cycle
                      data_address <= next_data_address;
                      next_data_address := next_data_address + 1;
                    end if;
                  else
                    decimation_count_cols := decimation_count_cols + 1;
                  end if;
                else
                  -- Update the index into the data buffer
                  buffer_index := buffer_index + 1;
                end if;
              end if;
              clock_count := clock_count + 1;
            end if;
          end if;
        when others =>
          -- Default to the start of an image
          state <= VS_RESET;
      end case;
    end if;
  end process adv7180_decoder;
  
  -- Generates flag required for HS_RESET state transition in main state machine
  hs_manager:  process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    type hs_state is (waiting, idle, transition);
    variable state : hs_state := idle;
  begin
    if(td_reset = '0') then
      state := idle;
      hs_flag <= '0';
    elsif(falling_edge(td_clk27)) then
      hs_flag <= '0';
      if(state = waiting) then
        if(td_hs = '0') then
          state := idle;
        end if;
      elsif(state = idle) then
        if(td_hs = '1') then
          hs_flag <= '1';
          state := transition;
        end if;
      elsif(state = transition) then
        hs_flag <= '1';
        state := waiting;
      else
        state := waiting;
      end if;
    end if;
  end process hs_manager;
  
  -- Generates flag required for VS_RESET state transition in main state machine
  vs_manager: process(td_data, td_clk27, td_hs, td_vs, td_reset) is
    type vs_state is (waiting, idle, transition);
    variable state : vs_state := idle;
  begin
    if(td_reset = '0') then
      state := idle;
      vs_flag <= '0';
    elsif(falling_edge(td_clk27)) then
      vs_flag <= '0';
      if(state = waiting) then
        if(td_vs = '0') then
          state := idle;
        end if;
      elsif(state = idle) then
        if(td_vs = '1') then
          vs_flag <= '1';
          state := transition;
        end if;
      elsif(state = transition) then
        vs_flag <= '1';
        state := waiting;
      else
        state := waiting;
      end if;
    end if;
  end process vs_manager;

end architecture adv7180;
