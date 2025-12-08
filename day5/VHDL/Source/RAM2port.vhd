
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY RAM2port IS
  PORT (
    clock : IN STD_LOGIC;
    data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    rdaddress : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    wraddress : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

    wren : IN STD_LOGIC;
    q : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
  );
END RAM2port;

ARCHITECTURE rtl OF RAM2port IS

  TYPE mem_t IS ARRAY(0 TO 2 ** 8 - 1) OF STD_LOGIC_VECTOR(127 DOWNTO 0);

  SIGNAL memory : mem_t := (OTHERS => (OTHERS => '0'));
  SIGNAL rdaddressD, wraddressD : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL dataD : STD_LOGIC_VECTOR(127 DOWNTO 0);
  SIGNAL wrenD : STD_LOGIC;
BEGIN

  q <= memory(to_integer(unsigned(rdaddressD)));

  PROCESS (clock)
  BEGIN
    IF rising_edge(clock) THEN
      IF wrenD = '1' THEN
        memory(to_integer(unsigned(wraddressD))) <= dataD;
      END IF;
    END IF;
  END PROCESS;

  PROCESS (clock)
  BEGIN
    IF rising_edge(clock) THEN
      wraddressD <= wraddress;
      rdaddressD <= rdaddress;

      dataD <= data;
      wrenD <= wren;
    END IF;
  END PROCESS;

END ARCHITECTURE;