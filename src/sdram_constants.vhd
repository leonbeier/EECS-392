package constants is
  constant DATA_WIDTH : natural := 32; -- bits
  
  component sdram is
  generic(
    size: natural := 32
  );
  port(
    clk: in std_logic;
    data_in: in std_logic_vector(DATA_WIDTH-1 downto 0);
    write_addr: in natural range 0 to size-1;
    read_addr: in natural range 0 to size-1;
    we: in std_logic;
    data_out: out std_logic_vector(DATA_WIDTH-1 downto 0)
  );
  end component sdram;
end package constants;