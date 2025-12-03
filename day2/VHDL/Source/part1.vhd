LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY part1 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    input : IN digit_array_t;
    valid : IN STD_LOGIC;

    count_o : OUT INTEGER;
    invalid_count_o : OUT INTEGER;

    invalid : OUT STD_LOGIC
  );
END part1;

ARCHITECTURE rtl OF part1 IS
  SIGNAL len : INTEGER RANGE 0 TO 10;
  SIGNAL test : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL invalid_count : INTEGER;
  SIGNAL count : INTEGER;
  SIGNAL highs, lows : STD_LOGIC_VECTOR(19 DOWNTO 0);
  SIGNAL invalid_i : STD_LOGIC;

BEGIN

  len <= get_length(input);

  PROCESS (input, len)
    VARIABLE high, low : STD_LOGIC_VECTOR(19 DOWNTO 0);

  BEGIN
    high := (OTHERS => '0');
    low := (OTHERS => '0');
    invalid_i <= '0';
    IF len MOD 2 = 0 AND valid = '1' THEN
      low := (OTHERS => '0');

      FOR i IN 0 TO 4 LOOP
        IF len / 2 - 1 >= i THEN
          low((i) * 4 + 3 DOWNTO ((i) * 4)) := input(10 - i);
          high((i) * 4 + 3 DOWNTO ((i) * 4)) := input(10 - len/2 - i);
        END IF;
      END LOOP;

      IF low = high THEN
        invalid_i <= '1';
      END IF;
    END IF;

    highs <= high;
    lows <= low;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      invalid_count <= 0;
      count <= 0;
    ELSIF rising_edge(clk) THEN

      IF valid = '1' AND invalid_i = '1' THEN
        invalid_count <= invalid_count + 1;
        count <= count + digit_to_int(input);
      ELSIF valid = '0' THEN
        invalid_count <= 0;
        count <= 0;
      END IF;
    END IF;
  END PROCESS;

  invalid <= invalid_i;

  count_o <= count;
  invalid_count_o <= invalid_count;

END ARCHITECTURE;