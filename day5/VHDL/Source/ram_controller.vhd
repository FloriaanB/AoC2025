LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE work.utils.ALL;

ENTITY ram_controller IS
  PORT (
    clk : IN STD_LOGIC;
    rst : IN STD_LOGIC;
    data_in : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
    instr : IN instr_t;
    ack : OUT STD_LOGIC;
    data_out : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
  );
END ram_controller;

ARCHITECTURE rtl OF ram_controller IS

  COMPONENT RAM2port IS
    PORT (
      clock : IN STD_LOGIC;
      data : IN STD_LOGIC_VECTOR(127 DOWNTO 0);
      rdaddress : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
      wraddress : IN STD_LOGIC_VECTOR(7 DOWNTO 0);

      wren : IN STD_LOGIC;
      q : OUT STD_LOGIC_VECTOR(127 DOWNTO 0)
    );
  END COMPONENT;

  SIGNAL ram_in, ram_out : STD_LOGIC_VECTOR(127 DOWNTO 0);
  SIGNAL rdaddress, wraddress : unsigned(7 DOWNTO 0);
  SIGNAL rdaddress_r, wraddress_r, address_save : unsigned(7 DOWNTO 0);

  SIGNAL wren, ack_d, ack_i : STD_LOGIC;

  SIGNAL length : unsigned(7 DOWNTO 0);

  TYPE state_t IS (active, pushing, pulling);
  SIGNAL state, next_state : state_t;
  SIGNAL delay : STD_LOGIC;

BEGIN

  bram : ram2port
  PORT MAP
  (
    clock => clk,
    data => ram_in,
    rdaddress => STD_LOGIC_VECTOR(rdaddress),
    wraddress => STD_LOGIC_VECTOR(wraddress),
    wren => wren,
    q => ram_out
  );

  PROCESS (instr, data_in, wraddress_r, ack_d, length, ram_out, rdaddress_r, state, delay)
  BEGIN
    wraddress <= wraddress_r;

    rdaddress <= rdaddress_r;

    wren <= '0';
    ack_i <= '0';
    next_state <= state;
    IF state = active THEN
      CASE instr IS
        WHEN insert =>

          IF wraddress_r = length THEN
            ack_i <= '1';
            wren <= '1';
            ram_in <= data_in;
            wraddress <= wraddress_r;
          ELSE
            next_state <= pushing;
          END IF;
        WHEN addrinc =>
          rdaddress <= rdaddress_r;
          ack_i <= ack_d;
        WHEN wr =>
          ram_in <= data_in;
          wren <= '1';
          ack_i <= '1';
        WHEN rdprev =>
          rdaddress <= rdaddress_r - 1;
        WHEN rdnext =>
          rdaddress <= rdaddress_r + 1;

        WHEN pop =>
          next_state <= pulling;

        WHEN OTHERS =>
      END CASE;
    ELSIF state = pushing AND delay = '0' THEN
      rdaddress <= rdaddress_r;
      wraddress <= wraddress_r;
      ram_in <= ram_out;
      wren <= '1';

      IF wraddress_r = address_save THEN
        next_state <= active;
        wren <= '1';
        ram_in <= data_in;
        ack_i <= '1';
      END IF;
    ELSIF state = pulling AND delay = '0' THEN
      rdaddress <= rdaddress_r;
      wraddress <= wraddress_r;
      ram_in <= ram_out;
      wren <= '1';

      IF wraddress_r = length THEN
        next_state <= active;
        wren <= '0';
        ram_in <= data_in;
        ack_i <= '1';
      END IF;
    END IF;
  END PROCESS;

  PROCESS (clk, rst)
  BEGIN
    IF rst = '1' THEN
      rdaddress_r <= (OTHERS => '0');
      wraddress_r <= (OTHERS => '0');
      address_save <= (OTHERS => '0');
      ack_d <= '0';
      length <= (OTHERS => '0');
      state <= active;
    ELSIF rising_edge(clk) THEN
      ack_d <= '0';
      state <= next_state;
      CASE instr IS
        WHEN addrinc =>
          rdaddress_r <= rdaddress_r + 1;
          wraddress_r <= wraddress_r + 1;

          ack_d <= '1';
        WHEN insert =>
          IF ack_i = '1' THEN
            length <= length + 1;
          END IF;
        WHEN resetaddr =>
          rdaddress_r <= (OTHERS => '0');
          wraddress_r <= (OTHERS => '0');
        WHEN OTHERS =>
      END CASE;

      IF next_state = pushing AND state /= pushing THEN
        rdaddress_r <= length - 1;
        wraddress_r <= length;
        address_save <= rdaddress_r;

      END IF;

      IF next_state = pulling AND state /= pulling THEN
        rdaddress_r <= rdaddress_r + 2;
        wraddress_r <= rdaddress_r + 1;
        address_save <= rdaddress_r;

      END IF;

      IF state /= next_state THEN
        delay <= '1';
      ELSE
        delay <= '0';
      END IF;

      CASE state IS
        WHEN pushing =>
          IF delay = '0' THEN
            rdaddress_r <= rdaddress_r - 1;
            wraddress_r <= wraddress_r - 1;
            delay <= '1';
          END IF;
        WHEN pulling =>
          IF delay = '0' THEN
            rdaddress_r <= rdaddress_r + 1;
            wraddress_r <= wraddress_r + 1;
            delay <= '1';
          END IF;
        WHEN OTHERS =>
      END CASE;

    END IF;
  END PROCESS;

  data_out <= ram_out WHEN state = active ELSE
              (OTHERS => '1');
  ack <= ack_i;

END ARCHITECTURE;