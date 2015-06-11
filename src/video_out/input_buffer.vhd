library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.video_out_constants.all;

entity input_buffer is
  generic(
    DATA_WIDTH : natural := 8;
    BUFFER_WIDTH : natural := 32
  );
  port(
    clk, reset : std_logic;
    enable : std_logic;
    data_in : in std_logic_vector(DATA_WIDTH-1 downto 0);
    data_out : out std_logic_vector(BUFFER_WIDTH-1 downto 0);
    ready : out std_logic
  );
end entity;

architecture behavioral of input_buffer is
  signal data_buffer : std_logic_vector(BUFFER_WIDTH-1 downto 0);
  
begin
  
  data_out <= data_buffer;
  
  fill_buffer : process(clk, reset)
  variable counter : natural := 0;
  variable full : std_logic;
  begin
    if falling_edge(clk) then  
        
      --full := '0';
      if (enable = '1') then
        data_buffer <= data_buffer(BUFFER_WIDTH-DATA_WIDTH-1 downto 0) & data_in;
        counter := counter + 1;
        full := '0';
        if (counter >= BUFFER_WIDTH / DATA_WIDTH) then
          full := '1';
          counter := 0;
        end if;
      end if;
      
      if (reset = '0') then
        data_buffer <= (others => '0');
        full := '0';
        counter := 0;
      end if;
      
      ready <= full;
    end if;
    
  end process;
  
  
end architecture;
