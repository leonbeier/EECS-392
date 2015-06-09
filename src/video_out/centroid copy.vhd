library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity centroid is
  generic(
    ROWS : natural := 240;
    COLS : natural := 320
  ); 
  port(
    clk : in std_logic;
    reset : in std_logic;
    pixel_buffer : in std_logic_vector(7 downto 0);
    
    center_row : out natural;
    center_col : out natural
  );
end entity centroid;

architecture behavior of centroid is

begin
  
  get_centroid : process(clk)
    variable total : natural := 0;
    variable row_sum, col_sum : natural := 0;
    variable row_index, col_index : natural := 0;
    variable counter : natural := 0;
    variable pixel : std_logic;
    variable center_row_temp, center_col_temp : natural;
    begin
    
    if rising_edge(clk) then
      
      pixel := pixel_buffer(0); --(counter);
      
      counter := counter + 1;
      if (counter >= 8) then
        counter := 0;
      end if;
      
      -- check if pixel is desired then add to counters
      if (pixel = '1') then
        -- used if to avoid div 0 err and using multipliers
        total := total + 1;
        row_sum := row_sum + row_index;
        col_sum := col_sum + col_index;
        
        center_row_temp := row_sum / total;
        center_col_temp := col_sum / total;
      end if;
      
      -- increment indices for col, row
      col_index := col_index + 1;
      if (col_index >= COLS) then 
        col_index := 0; 
        row_index := row_index + 1;
        if (row_index >= ROWS) then
          row_index := 0;
          total := 0;
          row_sum := 0;
          col_sum := 0;
          
          center_row <= center_row_temp;
          center_col <= center_col_temp;

        end if;
      end if;
      
      if (reset = '0') then
        total := 0;
        row_sum := 0;
        col_sum := 0;
        row_index := 0;
        col_index := 0;
      --complete <= '0';
      end if;
    end if;
    
  end process;
  
end architecture behavior;

