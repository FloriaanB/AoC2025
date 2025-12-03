LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;
USE std.textio.ALL;
USE std.env.finish;

ENTITY day3_tb IS
END day3_tb;

ARCHITECTURE sim OF day3_tb IS

  CONSTANT clk_hz : INTEGER := 100e6;
  CONSTANT clk_period : TIME := 1 sec / clk_hz;

  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst : STD_LOGIC := '1';

  SIGNAL input : STD_LOGIC_VECTOR(3 DOWNTO 0) := (OTHERS => '0');
  SIGNAL valid : STD_LOGIC := '0';
  SIGNAL ack : STD_LOGIC;
  SIGNAL output : unsigned(47 DOWNTO 0);

BEGIN

  clk <= NOT clk AFTER clk_period / 2;

  DUT : ENTITY work.part1(rtl)
    PORT MAP(
      clk => clk,
      rst => rst,

      input => input,
      valid => valid,
      output => output,
      ack => ack

    );

  SEQUENCER_PROC : PROCESS
    FILE input_file : text OPEN read_mode IS "input.txt";
    VARIABLE input_line : line;
    VARIABLE input_value : STRING(1 TO 101);
    VARIABLE i : INTEGER;
    VARIABLE lead_zeros : STD_LOGIC;
    VARIABLE vector : digit_array_t := (OTHERS => (OTHERS => '0'));

  BEGIN
    WAIT FOR clk_period * 2;

    rst <= '0';

    WAIT FOR clk_period * 10;

    WHILE NOT endfile(input_file) LOOP
      readLine(input_file, input_line);

      IF input_line'length > 0 THEN
        read(input_line, input_value(101 - input_line'length TO 100));

        vector := string_to_digits(input_value(1 TO 101));

        i := 0;
        lead_zeros := '1';
        WHILE i < vector'length LOOP
          IF vector(i) /= "0000" THEN
            lead_zeros := '0';
          ELSIF lead_zeros = '1' THEN
            i := i + 1;
          END IF;

          IF lead_zeros = '0' THEN
            valid <= '1';
            input <= vector(i);
            i := i + 1;
            WAIT FOR clk_period;
          END IF;
        END LOOP;
        valid <= '0';

        WAIT FOR clk_period;

        -- REPORT input_value;
      END IF;

      WAIT UNTIL ack = '1';
      WAIT FOR clk_period;

    END LOOP;
    input <= ((OTHERS => '0'));

    WAIT FOR clk_period * 10;
    REPORT to_string(output);

    finish;
  END PROCESS;

END ARCHITECTURE;