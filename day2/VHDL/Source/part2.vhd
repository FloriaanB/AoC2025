LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY part2 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    input : IN digit_array_t;
    valid : IN STD_LOGIC;

    count_o : OUT INTEGER;
    invalid_count_o : OUT INTEGER;

    invalid : OUT STD_LOGIC
  );
END part2;

ARCHITECTURE rtl OF part2 IS
  SIGNAL len : INTEGER RANGE 0 TO 10;
  SIGNAL test : STD_LOGIC_VECTOR(3 DOWNTO 0);

  SIGNAL invalid_count : INTEGER;
  SIGNAL count : INTEGER;
  SIGNAL highs, lows : STD_LOGIC_VECTOR(23 DOWNTO 0);
  SIGNAL high3s, middle3s, low3s : STD_LOGIC_VECTOR(11 DOWNTO 0);
  SIGNAL single_s : STD_LOGIC_VECTOR(10 DOWNTO 0);

  SIGNAL invalid_i : STD_LOGIC;

BEGIN

  len <= get_length(input);

  PROCESS (input, len)
    VARIABLE high, low : STD_LOGIC_VECTOR(23 DOWNTO 0);
    VARIABLE high3, middle3, low3 : STD_LOGIC_VECTOR(11 DOWNTO 0) := (OTHERS => '0');
    VARIABLE h1, h2, h3, h4, h5 : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
    VARIABLE single : STD_LOGIC_VECTOR(10 DOWNTO 0);

  BEGIN
    high := (OTHERS => '0');
    low := (OTHERS => '0');
    invalid_i <= '0';
    IF valid = '1' THEN

      IF len MOD 2 = 0 THEN
        low := (OTHERS => '0');
        high := (OTHERS => '0');

        FOR i IN 0 TO 4 LOOP
          IF len / 2 - 1 >= i THEN
            low((i) * 4 + 3 DOWNTO ((i) * 4)) := input(10 - i);
            high((i) * 4 + 3 DOWNTO ((i) * 4)) := input(10 - len/2 - i);
          END IF;
        END LOOP;

        IF low = high THEN
          invalid_i <= '1';
        END IF;

        FOR i IN 0 TO 1 LOOP
          h1(i * 4 + 3 DOWNTO i * 4) := input(10 - i);
          h2(i * 4 + 3 DOWNTO i * 4) := input(8 - i);
          h3(i * 4 + 3 DOWNTO i * 4) := input(6 - i);
          h4(i * 4 + 3 DOWNTO i * 4) := input(4 - i);
          h5(i * 4 + 3 DOWNTO i * 4) := input(2 - i);
        END LOOP;

        IF len = 6 AND h1 = h2 AND h3 = h2 THEN
          invalid_i <= '1';
        ELSIF len = 8 AND h1 = h2 AND h3 = h4 AND h3 = h2 THEN
          invalid_i <= '1';
        ELSIF h1 = h2 AND h3 = h4 AND h5 = h4 AND h3 = h1 THEN
          invalid_i <= '1';
        END IF;

      END IF;

    END IF;

    IF len = 9 THEN
      FOR i IN 0 TO 2 LOOP
        high3(i * 4 + 3 DOWNTO i * 4) := input(4 - i);
        middle3(i * 4 + 3 DOWNTO i * 4) := input(7 - i);
        low3(i * 4 + 3 DOWNTO i * 4) := input(10 - i);

      END LOOP;

      IF high3 = low3 AND middle3 = high3 THEN
        invalid_i <= '1';
      END IF;
    END IF;

    highs <= high;
    lows <= low;

    high3s <= high3;
    middle3s <= middle3;
    low3s <= low3;

    single := (OTHERS => '0');

    FOR i IN 1 TO 10 LOOP

      IF len - 1 >= i THEN
        IF input(10 - i) = input(10) THEN
          single(i) := '1';
        END IF;
      END IF;

    END LOOP;

    single_s <= single;

    IF popcount(single) = len - 1 AND len > 1 THEN
      invalid_i <= '1';
    END IF;

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