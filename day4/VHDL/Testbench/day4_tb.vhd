LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;
USE std.textio.ALL;
USE std.env.finish;

ENTITY day4_tb IS
END day4_tb;

ARCHITECTURE sim OF day4_tb IS

  CONSTANT clk_hz : INTEGER := 100e6;
  CONSTANT clk_period : TIME := 1 sec / clk_hz;

  SIGNAL clk : STD_LOGIC := '1';
  SIGNAL rst : STD_LOGIC := '1';

  SIGNAL input : STD_LOGIC := '0';
  SIGNAL valid : STD_LOGIC := '0';
  SIGNAL ack : STD_LOGIC;
  SIGNAL output : unsigned(47 DOWNTO 0);

  SIGNAL hor_sync : STD_LOGIC := '0';

  SIGNAL done : STD_LOGIC;
BEGIN

  clk <= NOT clk AFTER clk_period / 2;

  DUT : ENTITY work.part2(rtl)
    PORT MAP(
      clk => clk,
      rst => rst,

      input => input,
      valid => valid,
      hor_sync => hor_sync,
      done => done

    );

  SEQUENCER_PROC : PROCESS
    FILE input_file : text OPEN read_mode IS "input.txt";
    VARIABLE input_line : line;
    VARIABLE input_value : STRING(1 TO 141);
    VARIABLE lead_zeros : STD_LOGIC;
    VARIABLE vector : digit_array_t := (OTHERS => (OTHERS => '0'));

  BEGIN
    WAIT FOR clk_period * 2;

    rst <= '0';

    WAIT FOR clk_period * 10;

    WHILE NOT endfile(input_file) LOOP
      readLine(input_file, input_line);

      IF input_line'length > 0 THEN
        read(input_line, input_value(1 TO input_line'length));

        valid <= '1';

        FOR i IN 1 TO input_value'length LOOP

          IF i = input_value'length - 1 THEN
            hor_sync <= '1';
            WAIT FOR clk_period;

          END IF;
          IF input_value(i) = '.' THEN
            input <= '0';
            WAIT FOR clk_period;

          ELSIF input_value(i) = '@' THEN
            input <= '1';
            WAIT FOR clk_period;
          END IF;
        END LOOP;

        hor_sync <= '0';
      END IF;
    END LOOP;
    valid <= '0';
    WAIT UNTIL done = '1';
    WAIT FOR clk_period * 500;
    finish;
  END PROCESS;

END ARCHITECTURE;