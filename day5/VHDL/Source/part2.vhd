LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY part2 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    ranges : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    valid : IN STD_LOGIC;
    ack : OUT STD_LOGIC;
    done : IN STD_LOGIC
  );
END part2;

ARCHITECTURE rtl OF part2 IS

  COMPONENT ram_controller IS
    PORT (
      clk : IN STD_LOGIC;
      rst : IN STD_LOGIC;
      data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      instr : IN instr_t;

      ack : OUT STD_LOGIC;
      data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
  END COMPONENT;

  CONSTANT zero64 : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
  CONSTANT zero128 : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

  TYPE state_t IS (idle, initwr, busy, check, waiting, reseting, checkup, pop, adding);

  SIGNAL state, next_state : state_t;

  SIGNAL ram_in, ram_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
  SIGNAL hex, hin, lex, lin : STD_LOGIC_VECTOR(63 DOWNTO 0);
  SIGNAL instr : instr_t;

  SIGNAL ack_ram, bigger : STD_LOGIC;

  SIGNAL overlap : STD_LOGIC_VECTOR(1 DOWNTO 0);
  SIGNAL buff : STD_LOGIC_VECTOR(127 DOWNTO 0);
  SIGNAL delay : STD_LOGIC;
  SIGNAL sum : unsigned(63 DOWNTO 0);
  SIGNAL range_present : STD_LOGIC;

BEGIN

  ram : ram_controller
  PORT MAP(
    clk => clk,
    rst => rst,
    data_in => ram_in,
    instr => instr,
    ack => ack_ram,
    data_out => ram_out
  );

  PROCESS (state, valid, ack_ram, bigger, overlap, delay, done, range_present)
  BEGIN
    instr <= nop;
    ram_in <= (OTHERS => '0');
    next_state <= state;
    ack <= '0';
    CASE state IS
      WHEN idle =>
        IF valid = '1' THEN
          next_state <= initwr;
        END IF;
      WHEN initwr =>
        ram_in <= ranges;
        instr <= insert;
        next_state <= busy;
        ack <= '1';
      WHEN waiting =>
        IF valid = '1' THEN
          next_state <= busy;
        ELSIF done = '1' THEN
          next_state <= adding;
        END IF;
      WHEN busy =>
        instr <= rd;
        next_state <= check;

      WHEN check =>
        IF range_present = '1' THEN
          next_state <= reseting;
        ELSIF overlap = "01" THEN
          instr <= wr;
          ram_in <= ram_out(127 DOWNTO 64) & ranges(63 DOWNTO 0);
          next_state <= checkup;
        ELSIF overlap = "10" THEN
          instr <= wr;
          ram_in <= ranges(127 DOWNTO 64) & ram_out(63 DOWNTO 0);
          next_state <= reseting;
        ELSIF overlap = "11" THEN
          instr <= wr;
          ram_in <= ranges(127 DOWNTO 0);
          next_state <= reseting;
        ELSIF bigger = '1' THEN
          next_state <= busy;
          instr <= addrinc;

        ELSE
          instr <= insert;
          ram_in <= ranges;
          IF ack_ram = '1' THEN
            next_state <= reseting;
          END IF;

        END IF;
      WHEN checkup =>

        instr <= rdnext;
        IF delay = '0' THEN
          IF overlap = "01" THEN
            instr <= wr;
            ram_in <= ram_out(127 DOWNTO 64) & buff(63 DOWNTO 0);
            next_state <= pop;
          ELSIF overlap = "10" THEN
            instr <= wr;
            ram_in <= buff(127 DOWNTO 64) & ram_out(63 DOWNTO 0);
            next_state <= pop;
          ELSE
            next_state <= reseting;
          END IF;
        END IF;
      WHEN pop =>
        instr <= pop;
        IF ack_ram = '1' THEN
          next_state <= reseting;
        END IF;
      WHEN reseting =>
        instr <= resetaddr;
        next_state <= waiting;
        ack <= '1';
      WHEN adding =>
        instr <= addrinc;

        IF ram_out = zero128 THEN
          next_state <= idle;
        END IF;

      WHEN OTHERS =>
    END CASE;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      state <= idle;
      buff <= (OTHERS => '0');
      delay <= '0';
      sum <= (OTHERS => '0');
    ELSIF rising_edge(clk) THEN
      state <= next_state;
      delay <= '0';
      IF next_state = checkup AND state /= checkup THEN
        buff <= ram_in;
        delay <= '1';
      END IF;

      IF state = adding AND ack_ram = '1' AND lex /= zero64 THEN
        sum <= sum + unsigned(hex) - unsigned(lex) + 1;
      END IF;

    END IF;
  END PROCESS;

  lex <= ram_out(127 DOWNTO 64);
  hex <= ram_out(63 DOWNTO 0);

  lin <= buff(127 DOWNTO 64) WHEN state = checkup ELSE
         ranges(127 DOWNTO 64);
  hin <= buff(63 DOWNTO 0) WHEN state = checkup ELSE
         ranges(63 DOWNTO 0);

  bigger <= '0' WHEN ram_out = zero128 ELSE
            '1' WHEN ram_out(127 DOWNTO 64) < ranges(127 DOWNTO 64) ELSE
            '0';

  range_present <= '1' WHEN lin >= lex AND hex >= hin ELSE
                   '0';

  overlap <= "00" WHEN state = idle ELSE
             "11" WHEN lin < lex AND hin > hex ELSE
             
             "01" WHEN lin < hex AND hin > hex ELSE
             "10" WHEN hin > lex AND lin < lex ELSE
             "01" WHEN lin = hex ELSE
             "10" WHEN lex = hin ELSE
             
             "00";

END ARCHITECTURE;