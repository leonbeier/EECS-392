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
    pixel : in std_logic;
    
    center_row : out natural;
    center_col : out natural;
    complete : out std_logic
  );
end entity centroid;

architecture behavior of centroid is

begin
  
  get_centroid : process(clk)
    variable total : natural := 0;
    variable row_sum, col_sum : natural := 0;
    variable row_index, col_index : natural := 0;
        
    begin
    
    if (reset = '1') then
      total := 0;
      row_sum := 0;
      col_sum := 0;
      row_index := 0;
      col_index := 0;
      complete <= '0';
    
    elsif falling_edge(clk) then
      -- check if pixel is desired then add to counters
      if (pixel = '1') then
        -- used if to avoid div 0 err and using multipliers
        total := total + 1;
        row_sum := row_sum + row_index;
        col_sum := col_sum + col_index;
        
        center_row <= row_sum / total;
        center_col <= col_sum / total;
      end if;
      
      -- initialize new frame
      if (col_index = 0 and row_index = 0) then
        total := 0;
        row_sum := 0;
        col_sum := 0;
        complete <= '0';
      end if;
      
      -- increment indices for col, row
      col_index := col_index + 1;
      if (col_index = COLS) then 
        col_index := 0; 
        row_index := row_index + 1;
        if (row_index = ROWS) then
          row_index := 0;
          complete <= '1';

        end if;
      end if;
      
    end if;
    
  end process;
  
end architecture behavior;
