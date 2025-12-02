LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

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

BEGIN

  clk <= NOT clk AFTER clk_period / 2;

  DUT : ENTITY work.part2(rtl)
    PORT MAP(
      clk => clk,
      rst => rst,
      value => value,
      direction => direction,
      valid => valid,
      code_out => code

    );

  SEQUENCER_PROC : PROCESS
    FILE input_file : text OPEN read_mode IS "input.txt";
    VARIABLE input_line : line;
    VARIABLE input_value : STRING(1 TO 100);
    VARIABLE int_string : STRING(1 TO 99);
    VARIABLE value_int : INTEGER;

  BEGIN
    WAIT FOR clk_period * 2;

    rst <= '0';

    WHILE NOT ENDfile(input_file) LOOP
      readLine(input_file, input_line);

      input_value := (OTHERS => ' ');

      IF input_line'length > 0 THEN
        read(input_line, input_value(1 TO input_line'length));

        IF input_value(1) = 'L' THEN
          direction <= '1';
        ELSE
          direction <= '0';
        END IF;
        -- REPORT(input_value);s

        value <= to_signed((INTEGER'value(input_value(2 TO 100))), 16);
        valid <= '1';

      END IF;
      WAIT FOR clk_period;
      valid <= '0';
    END LOOP;

    WAIT FOR clk_period * 10;

    REPORT to_string(to_integer(code));

    finish;
  END PROCESS;

END ARCHITECTURE;