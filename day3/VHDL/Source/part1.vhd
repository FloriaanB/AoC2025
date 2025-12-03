LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY part1 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    input : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    valid : IN STD_LOGIC;

    output : OUT unsigned(47 DOWNTO 0);
    ack : OUT STD_LOGIC

  );
END part1;

ARCHITECTURE rtl OF part1 IS

  SIGNAL high, low : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL count_output : unsigned(47 DOWNTO 0);
  SIGNAL count_input, count : INTEGER RANGE 0 TO 101;
  SIGNAL validd : STD_LOGIC;
  SIGNAL mem : digit_array_t := (OTHERS => (OTHERS => '0'));
  SIGNAL ack_i : STD_LOGIC;
  SIGNAL busy : STD_LOGIC;
  SIGNAL mem_out : STD_LOGIC_VECTOR(3 DOWNTO 0);

BEGIN

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      high <= (OTHERS => '0');
      low <= (OTHERS => '0');
      count <= 0;
      busy <= '0';
    ELSIF rising_edge(clk) THEN
      IF ack_i = '1' THEN
        count <= 0;
        low <= (OTHERS => '0');
        high <= (OTHERS => '0');

      ELSIF valid = '0' THEN
        IF count < count_input + 1 AND busy = '1' THEN
          count <= count + 1;

          IF unsigned(mem_out) > unsigned(high) AND count < count_input THEN
            high <= mem_out;
            low <= (OTHERS => '0');
          ELSIF unsigned(mem_out) > unsigned(low) THEN
            low <= mem_out;
          ELSIF unsigned(mem_out) = unsigned(low) THEN
            low <= mem_out;
          END IF;
        END IF;

      END IF;
      IF busy = '1' AND ack_i = '1' THEN
        busy <= '0';
      ELSIF valid = '1' THEN
        busy <= '1';
      END IF;
    END IF;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      count_output <= (OTHERS => '0');
      count_input <= 0;

    ELSIF rising_edge(clk) THEN

      validD <= valid;
      IF ack_i = '1' THEN
        count_output <= resize((unsigned(high)) * 10, 48) + resize(unsigned(low), 48) + count_output;
      END IF;
      mem(count_input) <= input;

      IF valid = '1' AND count_input < 99 THEN
        count_input <= count_input + 1;
      ELSIF ack_i = '1' THEN
        count_input <= 0;
      END IF;
    END IF;
  END PROCESS;

  output <= count_output;
  ack <= ack_i;
  ack_i <= '1' WHEN count = count_input + 1 AND count /= 0 ELSE
           '0';

  mem_out <= mem(count);
END ARCHITECTURE;