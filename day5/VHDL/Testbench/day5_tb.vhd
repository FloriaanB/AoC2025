LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

USE std.textio.ALL;
USE std.env.finish;

ENTITY day5_tb IS
END day5_tb;

ARCHITECTURE sim OF day5_tb IS

  CONSTANT clk_hz : INTEGER := 100e6;
  CONSTANT clk_period : TIME := 1 sec / clk_hz;

  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst : STD_LOGIC := '1';

  SIGNAL value, code : signed(15 DOWNTO 0) := (OTHERS => '0');
  SIGNAL direction, valid : STD_LOGIC := '0';

  SIGNAL input : digit_array_t := (OTHERS => (OTHERS => '0'));
  SIGNAL done : STD_LOGIC := '0';

  SIGNAL invalid : STD_LOGIC;

  SIGNAL ranges : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');
  SIGNAL ack : STD_LOGIC;

BEGIN

  clk <= NOT clk AFTER clk_period / 2;

  dut : ENTITY work.part2
    PORT MAP(
      clk => clk,
      rst => rst,
      ranges => ranges,
      valid => valid,
      ack => ack,
      done => done
    );

  SEQUENCER_PROC : PROCESS
    FILE input_file : text OPEN read_mode IS "input.txt";
    VARIABLE input_line : line;
    VARIABLE input_value : STRING(1 TO 1000) := (OTHERS => 'x');
    VARIABLE tokInt1, tokInt2 : unsigned(63 DOWNTO 0) := (OTHERS => '0');
    VARIABLE dash_pos, end_pos : INTEGER := 0;

    VARIABLE token1, token2 : STRING(1 TO 16) := (OTHERS => '0'); -- Up to 100 pieces

  BEGIN
    WAIT FOR clk_period * 2;

    rst <= '0';

    WHILE NOT endfile(input_file) LOOP
      readLine(input_file, input_line);

      dash_pos := 0;
      end_pos := 0;
      token1 := (OTHERS => '0');
      token2 := (OTHERS => '0');

      input_value := (OTHERS => 'x');

      IF input_line'length > 0 THEN
        read(input_line, input_value(1 TO input_line'length));

        FOR i IN input_value'RANGE LOOP
          -- REPORT (to_string(input_value(i)));

          IF input_value(i) = '-' THEN
            dash_pos := i;
            -- REPORT to_string(dash_pos);

          ELSIF input_value(i) = 'x' THEN
            end_pos := i;
            EXIT;
          END IF;

        END LOOP;

        -- REPORT to_string(dash_pos);

        -- REPORT input_value(1 TO dash_pos - 1);

        -- REPORT to_string(12 - end_pos + dash_pos);
        IF dash_pos > 0 THEN
          token1(18 - dash_pos TO 16) := input_value(1 TO dash_pos - 1);
        ELSE
          EXIT;
        END IF;
        token2(18 - end_pos + dash_pos TO 16) := input_value(dash_pos + 1 TO end_pos - 1);

        tokInt1 := string_to_integer(token1);
        tokInt2 := string_to_integer(token2);

        ranges <= STD_LOGIC_VECTOR(tokInt1 & tokInt2);

        valid <= '1';
        WAIT FOR clk_period;
        valid <= '0';

        WAIT UNTIL ack = '1';
        WAIT FOR clk_period;

      END IF;

    END LOOP;
    done <= '1';
    valid <= '0';
    ranges <= (OTHERS => '0');

    WAIT FOR clk_period * 10000;

    -- REPORT to_string(to_integer(code));

    finish;
  END PROCESS;

END ARCHITECTURE;