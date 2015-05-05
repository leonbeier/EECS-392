library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.tracker_constants.all;
--use WORK.fifo.all;

entity uart_tb is
  port(
	tb:in std_logic
  );
end entity uart_tb;

architecture behavioral of uart_tb is

component uart is
  port (
    -- internal clock and reset signals
    clock_50 : in std_logic;
    reset : in std_logic;
    
    -- uart communication dependent
    baud_rate : in natural := DEFAULT_BAUD_RATE;
    rx : in std_logic;
    tx : inout std_logic;
    
    -- tx fifo 
    read : in std_logic;
    empty : in std_logic;
    idata : in std_logic_vector(7 downto 0);
    -- rx fifo
    write : out std_logic;
    full : in std_logic;
    odata : out std_logic_vector(7 downto 0)
    
    
  );
end component uart;

    signal clock_50 : std_logic;
    signal reset : std_logic;
    
    -- uart communication dependent
    signal baud_rate : natural;
    signal rx : std_logic;
    signal tx : std_logic;
    --tx fifo
    signal read : std_logic;
    signal empty : std_logic;
    signal idata : std_logic_vector(7 downto 0);
    -- fifo control
    signal write : std_logic;
    signal full : std_logic;
    signal odata : std_logic_vector(7 downto 0);
    


begin

ua:uart port map(clock_50,reset,baud_rate,rx,tx,read,empty, idata, write,full,odata);

test: process is
begin
	clock_50 <= '0';
	reset <= '1';
	baud_rate <= DEFAULT_BAUD_RATE;
	rx <= '1'; --default high
	empty <= '0';
	idata <= "01101010";
	full <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	reset <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	rx <= '0';  --0 starts recieving
	wait for 10 ns;
	clock_50 <= '1';
--INIT
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--Start reading
	wait for 10 ns;
	clock_50 <= '0';
	rx<='1';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 1
	wait for 10 ns;
	clock_50 <= '0';
	rx<='0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 2
	wait for 10 ns;
	clock_50 <= '0';
	rx<='1';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 3
	wait for 10 ns;
	clock_50 <= '0';
	rx<='0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 4
	wait for 10 ns;
	clock_50 <= '0';
	rx<='1';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 5
	wait for 10 ns;
	clock_50 <= '0';
	rx<='0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 6
	wait for 10 ns;
	clock_50 <= '0';
	rx<='1';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 7
	wait for 10 ns;
	clock_50 <= '0';
	rx<='0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--bit 8
	wait for 10 ns;
	clock_50 <= '0';
	rx<='0'; -- 0 stops transmission
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--stop bit
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
--another half cycle to re-sync
	wait for 10 ns;
	clock_50 <= '0';
	rx <= '1';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 50 ns;
----------------------------------------------------------tx test------------



	read <= '1';
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	read <= '0';
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	wait for 10 ns;
	clock_50 <= '0';
	wait for 10 ns;
	clock_50 <= '1';
	


	wait;
end process;
end architecture;
