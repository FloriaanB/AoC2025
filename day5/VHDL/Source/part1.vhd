LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY part1 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    ranges : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    valid : IN STD_LOGIC;
    ack : OUT STD_LOGIC
  );
END part1;

ARCHITECTURE rtl OF part1 IS

  COMPONENT RAM IS
    PORT (
      clock : IN STD_LOGIC;
      data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      wren : IN STD_LOGIC;
      q : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
  END COMPONENT;

  CONSTANT zero64 : STD_LOGIC_VECTOR(63 DOWNTO 0) := (OTHERS => '0');
  CONSTANT zero128 : STD_LOGIC_VECTOR(127 DOWNTO 0) := (OTHERS => '0');

  SIGNAL count, length : unsigned(7 DOWNTO 0);

  SIGNAL ack_i : STD_LOGIC;

  TYPE state_t IS (idle, loading, busy);
  SIGNAL state, next_state : state_t;

  SIGNAL wren : STD_LOGIC;
  SIGNAL address : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL ram_in, ram_out, range_data : STD_LOGIC_VECTOR(127 DOWNTO 0);
  SIGNAL within_range, within_range_r : STD_LOGIC;
  SIGNAL sum : unsigned(31 DOWNTO 0);

BEGIN

  bram : ram
  PORT MAP
  (
    clock => clk,
    data => ram_in,
    address => address,
    wren => wren,
    q => ram_out);

  PROCESS (state, valid, ranges)
  BEGIN
    CASE state IS
      WHEN idle =>
        IF valid = '1' THEN
          next_state <= loading;
        END IF;
      WHEN loading =>
        IF valid = '1' AND ranges(127 DOWNTO 64) = zero64 THEN
          next_state <= busy;
        END IF;
      WHEN busy =>
        IF ranges = zero128 THEN
          next_state <= idle;
        END IF;
      WHEN OTHERS =>
    END CASE;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      state <= idle;
    ELSIF rising_edge(clk) THEN
      state <= next_state;
    END IF;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      count <= (OTHERS => '0');
      ack_i <= '0';
      length <= (OTHERS => '0');
      sum <= (OTHERS => '0');
      within_range_r <= '0';
    ELSIF rising_edge(clk) THEN
      IF state = idle AND next_state = idle THEN
        count <= (OTHERS => '0');
        ack_i <= '0';
        length <= (OTHERS => '0');
        within_range_r <= '0';
      ELSIF (state = loading AND next_state = loading) OR next_state = loading THEN
        ack_i <= valid;
        IF valid = '1' THEN
          count <= count + 1;
        END IF;

        length <= count;
      ELSIF state = busy THEN

        IF count < length + 1 THEN
          count <= count + 1;
        ELSE
          count <= (OTHERS => '0');
        END IF;

        IF within_range = '1' THEN
          within_range_r <= '1';
        END IF;

        IF count = length + 1 THEN
          ack_i <= '1';
          IF within_range_r = '1' THEN
            sum <= sum + 1;
          END IF;
          within_range_r <= '0';
        ELSE
          ack_i <= '0';
        END IF;
      END IF;
    END IF;

    IF next_state = busy AND state /= busy THEN
      count <= (OTHERS => '0');
    END IF;
  END PROCESS;

  ack <= ack_i;

  address <= STD_LOGIC_VECTOR(count) WHEN count < length ELSE
             STD_LOGIC_VECTOR(count) WHEN (state = loading AND next_state = loading) OR next_state = loading ELSE
             (OTHERS => '0');
  ram_in <= ranges WHEN (state = loading AND next_state = loading) OR next_state = loading ELSE
            (OTHERS => '0');
  wren <= valid WHEN (state = loading AND next_state = loading) OR next_state = loading ELSE
          '0';

  range_data <= ram_out WHEN state = busy AND count <= length ELSE
                (OTHERS => '0');

  within_range <= '1' WHEN unsigned(ranges(63 DOWNTO 0)) >= unsigned(range_data(127 DOWNTO 64)) AND
                  unsigned(range_data(63 DOWNTO 0)) >= unsigned(ranges(63 DOWNTO 0)) AND count <= length AND 0 < count ELSE
                  '0';
END ARCHITECTURE;