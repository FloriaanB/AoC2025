LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY part1 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    value : IN signed(15 DOWNTO 0);
    direction : IN STD_LOGIC;
    valid : IN STD_LOGIC;
    code_out : OUT signed(15 DOWNTO 0);
    done : OUT STD_LOGIC
  );
END part1;

ARCHITECTURE rtl OF part1 IS

  SIGNAL score_r, value_r : signed(15 DOWNTO 0);
  SIGNAL valid_d : STD_LOGIC;
  SIGNAL code : signed(15 DOWNTO 0);

  SIGNAL score : signed(15 DOWNTO 0);

BEGIN

  PROCESS (clk, rst)

  BEGIN
    IF rst = '1' THEN
      code <= (OTHERS => '0');
      score_r <= to_signed(50, 16);
      valid_d <= '0';
      done <= '0';
    ELSIF rising_edge(clk) THEN
      IF valid = '1' THEN

        IF score < 0 THEN
          score_r <= 100 + score;
        ELSIF score >= 100 THEN
          score_r <= score - 100;
        ELSE
          score_r <= score;
        END IF;

        IF score_r = 0 THEN
          code <= code + 1;
        END IF;

        valid_d <= valid;

        done <= valid_d AND NOT valid;

      END IF;
    END IF;
  END PROCESS;

  code_out <= code;

  score <= score_r + value MOD 100 WHEN direction = '1' ELSE
           score_r - value MOD 100;

END ARCHITECTURE;