library IEEE;

use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;

entity uart is
  port (
    baud_rate : in integer = DEFAULT_BAUD_RATE;
    rx : in std_logic,
    tx : in std_logic,
  );
end entity uart;

architecture uart of uart is
  -- clock control
  signal serial_clk : std_logic;
  signal counter_clk : integer;
  
  -- uart control
  signal uart_rx_state : uart_state;
  signal uart_rx_next : uart_state
  signal uart_tx_state : uart_state;
  signal uart_tx_next : uart_state;
begin

  uart_clk_trigger : process(CLOCK_50, RESET_N) is
    -- check the baud rate and set the counter
    variable internal_count : integer := 0;
    variable bit_count : unsigned integer := 0;
    variable bit_buffer : std_logic_vector(7 downto 0);
  begin
    if(internal_count = counter_clk) then
      case(uart_state) is
        -- check for a start bit
        when INIT =>
          if(rx = '1') then
            uart_rx_next <= ACTIVE;
          end if;
        when ACTIVE =>
          -- load the next 8 bits into a temporary buffer
          bit_buffer(bit_count) <= rx;
          bit_count := bit_count + 1;
          if(bit_count = 7) then
            uart_rx_next <= STOP;
          end if;
        when STOP =>
          -- check if the next one or two bits are high
          --  if they are high then write the buffer to the fifo
          if(rx = '1') then
            -- load data into byte fifo
            -- TODO
          end if;
    end if;
  end process buffer_proc;
  
  uart_state_machine: process()
    
  begin
    -- TODO
  end process uart_state_machine;

end architecture uart; 