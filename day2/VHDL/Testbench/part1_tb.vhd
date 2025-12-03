LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

USE std.textio.ALL;
USE std.env.finish;

ENTITY part1_tb IS
END part1_tb;

ARCHITECTURE sim OF part1_tb IS

  CONSTANT clk_hz : INTEGER := 100e6;
  CONSTANT clk_period : TIME := 1 sec / clk_hz;

  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst : STD_LOGIC := '1';

  SIGNAL value, code : signed(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL direction, valid : STD_LOGIC := '0';

  SIGNAL input : digit_array_t := (OTHERS => (OTHERS => '0'));
  SIGNAL done : STD_LOGIC := '0';

  SIGNAL invalid : STD_LOGIC;

BEGIN

  clk <= NOT clk AFTER clk_period / 2;

  DUT : ENTITY work.part2(rtl)
    PORT MAP(
      clk => clk,
      rst => rst,
      input => input,
      valid => valid,

      invalid => invalid

    );

  SEQUENCER_PROC : PROCESS
    FILE input_file : text OPEN read_mode IS "input.txt";
    VARIABLE input_line : line;
    VARIABLE input_value : STRING(1 TO 1000);
    VARIABLE int_string : STRING(1 TO 99);
    VARIABLE value_int : INTEGER;
    VARIABLE dash_pos, comma_pos : INTEGER := 0;

    VARIABLE token1, token2 : STRING(1 TO 10) := (OTHERS => '0'); -- Up to 100 pieces
    VARIABLE token_count : NATURAL := 0;
    VARIABLE current : STRING(1 TO 10000);
    VARIABLE current_len : NATURAL := 0;

    VARIABLE numlow, numhigh, j : unsigned(33 DOWNTO 0);

  BEGIN
    WAIT FOR clk_period * 2;

    rst <= '0';

    WHILE NOT endfile(input_file) LOOP
      readLine(input_file, input_line);

      IF input_line'length > 0 THEN
        read(input_line, input_value(1 TO input_line'length));
        FOR i IN input_value'RANGE LOOP

          IF input_value(i) = '-' THEN
            dash_pos := i;
            token1 := (OTHERS => '0');

            token1(12 - (dash_pos - comma_pos) TO 10) := input_value(comma_pos + 1 TO dash_pos - 1);
            REPORT (token1);
          END IF;

          IF input_value(i) = ',' THEN
            comma_pos := i;
            token2 := (OTHERS => '0');

            token2(12 - (comma_pos - dash_pos) TO 10) := input_value(dash_pos + 1 TO comma_pos - 1);

            numlow := string_to_integer(token1);
            numhigh := string_to_integer(token2);

            -- REPORT to_string(to_integer(numlow));
            -- REPORT to_string(to_integer(numhigh));

            input <= (OTHERS => (OTHERS => '0'));

            j := numLow;

            WHILE j < numHigh + 1 LOOP

              valid <= '1';
              input <= extract_digits(j);
              j := j + 1;
              WAIT FOR clk_period * 1;
            END LOOP;
          END IF;
        END LOOP;

      END IF;

      WAIT FOR clk_period;

    END LOOP;
    valid <= '0';

    WAIT FOR clk_period * 10;

    -- REPORT to_string(to_integer(code));

    finish;
  END PROCESS;

END ARCHITECTURE;