LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY part2 IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    input : IN STD_LOGIC;
    hor_sync : IN STD_LOGIC;
    valid : IN STD_LOGIC;

    output_valid : OUT STD_LOGIC;
    output : OUT STD_LOGIC;
    done : OUT STD_LOGIC
  );
END part2;

ARCHITECTURE rtl OF part2 IS

  COMPONENT RAM IS
    PORT (
      clock : IN STD_LOGIC;
      data : IN STD_LOGIC_VECTOR(141 DOWNTO 0);
      address : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      wren : IN STD_LOGIC;
      q : OUT STD_LOGIC_VECTOR(141 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL count_x, count_y : unsigned(7 DOWNTO 0);
  SIGNAL x_size, y_size : unsigned(7 DOWNTO 0);

  SIGNAL memBuffer : STD_LOGIC_VECTOR(141 DOWNTO 0);
  SIGNAL addr : STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL ramIn, ramOut : STD_LOGIC_VECTOR(141 DOWNTO 0);
  SIGNAL wren : STD_LOGIC;
  SIGNAL outbuff0, outbuff1, outbuff2 : STD_LOGIC_VECTOR(141 DOWNTO 0);

  TYPE state_t IS (idle, loading, reading, busy, redo, writing);
  SIGNAL state, next_state : state_t := idle;
  SIGNAL load_count : unsigned(2 DOWNTO 0);

  SIGNAL sum, moveable : INTEGER;
  SIGNAL moved : INTEGER;
  SIGNAL x_lim_low, x_lim_high : INTEGER;
  SIGNAL input_r, hor_sync_r, init_load : STD_LOGIC;

BEGIN

  bram : ram
  PORT MAP(
    clock => clk,
    data => ramIn,
    address => addr,
    wren => wren,
    q => ramOut
  );

  PROCESS (state, valid, load_count, count_x, x_size, count_y, y_size, moveable)
  BEGIN
    next_state <= state;
    CASE state IS
      WHEN idle =>
        IF valid = '1' THEN
          next_state <= loading;
        END IF;
      WHEN loading =>
        IF valid = '0' THEN
          next_state <= reading;
        END IF;
      WHEN reading =>
        IF load_count = 3 THEN
          next_state <= busy;
        END IF;
      WHEN writing =>
        IF count_y = y_size AND moveable = 0 THEN
          next_state <= idle;
        ELSIF count_y = y_size THEN
          next_state <= redo;
        ELSE
          next_state <= reading;
        END IF;
      WHEN busy =>

        IF count_x = x_size THEN
          next_state <= writing;
        END IF;

      WHEN redo =>

        next_state <= reading;
      WHEN OTHERS =>
    END CASE;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      state <= idle;
      hor_sync_r <= '0';
      input_r <= '0';
    ELSIF rising_edge(clk) THEN
      state <= next_state;
      input_r <= input;
      hor_sync_r <= hor_sync;
    END IF;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      count_x <= to_unsigned(1, count_x'length);
      count_y <= to_unsigned(1, count_y'length);
      memBuffer <= (OTHERS => '0');
      load_count <= (OTHERS => '0');

      outbuff0 <= (OTHERS => '0');
      outbuff1 <= (OTHERS => '0');
      outbuff2 <= (OTHERS => '0');
      moveable <= 0;

      init_load <= '1';

      moved <= 0;

    ELSIF rising_edge(clk) THEN

      IF state = loading THEN
        memBuffer(to_integer(count_x)) <= input_r;

        IF hor_sync_r = '0' THEN
          count_x <= count_x + 1;
        ELSE
          memBuffer <= (OTHERS => '0');
          count_y <= count_y + 1;
          count_x <= to_unsigned(1, count_x'length);
          x_size <= count_x - 1;
        END IF;
      ELSIF state = reading THEN
        IF init_load = '1' THEN
          outbuff2 <= ramOut;
          outbuff1 <= outbuff2;
          membuffer <= outbuff2;

          outbuff0 <= outbuff1;
        ELSIF load_count = 3 THEN
          outbuff2 <= ramOut;
          outbuff1 <= outbuff2;
          membuffer <= outbuff2;
          outbuff0 <= outbuff1;
        END IF;

        count_x <= to_unsigned(1, count_y'length);

        IF load_count < 3 THEN
          load_count <= load_count + 1;
        END IF;
      ELSIF state = busy THEN

        init_load <= '0';

        IF count_x < x_size + 1 THEN
          count_x <= count_x + 1;

        END IF;
        IF sum < 4 AND outbuff1(to_integer(count_x)) = '1' THEN
          moveable <= moveable + 1;
          membuffer(to_integer(count_x)) <= '0';
        END IF;

        load_count <= to_unsigned(2, load_count'length);

      ELSIF state = redo THEN
        count_x <= to_unsigned(1, count_x'length);
        count_y <= to_unsigned(1, count_y'length);

        moved <= moved + moveable;
        moveable <= 0;

        init_load <= '1';

        load_count <= (OTHERS => '0');
      ELSIF state = writing THEN
        count_y <= count_y + 1;

      END IF;

      IF next_state = reading THEN
        IF state = loading THEN
          y_size <= count_y;
          count_y <= to_unsigned(1, count_y'length);
        END IF;
      END IF;

    END IF;
  END PROCESS;

  output_valid <= '1' WHEN state = busy ELSE
                  '0';
  output <= '1' WHEN sum < 4 AND outbuff1(to_integer(count_x)) = '1' ELSE
            '0';

  addr <= STD_LOGIC_VECTOR(resize(count_y, addr'length)) WHEN hor_sync_r = '1' OR state = writing ELSE
          STD_LOGIC_VECTOR(resize(count_y - 1 + load_count, addr'length)) WHEN state = reading ELSE
          -- STD_LOGIC_VECTOR(resize(count_y, addr'length)) WHEN state = reading ELSE
          
          (OTHERS => '0');
  ramin <= memBuffer;
  wren <= '1' WHEN state = writing ELSE
          hor_sync_r;

  x_lim_low <= to_integer(count_x - 1);
  x_lim_high <= to_integer(count_x + 1);

  sum <= popcount(outbuff0(x_lim_high DOWNTO x_lim_low) & outbuff2(x_lim_high DOWNTO x_lim_low) & outbuff1(x_lim_high) & outbuff1(x_lim_low)) WHEN state = busy ELSE
         0;

  done <= '1' WHEN state = idle ELSE
          '0';

END ARCHITECTURE;