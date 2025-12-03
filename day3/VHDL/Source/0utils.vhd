LIBRARY IEEE;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE ieee.std_logic_textio.ALL; -- Only needed if you are dealing with text I/O
USE std.textio.ALL; -- Only needed if you are dealing with text I/O

PACKAGE Utils IS

  -- ===========================
  -- General Type Declarations
  -- ===========================

  TYPE digit_array_t IS ARRAY(0 TO 100) OF STD_LOGIC_VECTOR(3 DOWNTO 0);
  TYPE digit_array12_t IS ARRAY(0 TO 11) OF STD_LOGIC_VECTOR(3 DOWNTO 0);

  FUNCTION string_to_integer(s : STRING) RETURN unsigned;
  FUNCTION extract_digits(input : unsigned) RETURN digit_array_t;
  FUNCTION digit_to_int(input : digit_array_t) RETURN INTEGER;
  FUNCTION string_to_digits(input : STRING) RETURN digit_array_t;

END PACKAGE Utils;
PACKAGE BODY Utils IS

  FUNCTION string_to_integer(s : STRING) RETURN unsigned IS
    VARIABLE result : unsigned(33 DOWNTO 0) := (OTHERS => '0');
    VARIABLE resulti : unsigned(33 DOWNTO 0) := (OTHERS => '0');
  BEGIN
    FOR i IN s'RANGE LOOP
      IF s(i) >= '0' AND s(i) <= '9' THEN

        result := to_unsigned(CHARACTER'pos(s(i)) - CHARACTER'pos('0'), 34);
        resulti := resize(resulti * 10, 34) + result;

      END IF;
    END LOOP;
    RETURN resulti;
  END FUNCTION;

  FUNCTION extract_digits(input : unsigned) RETURN digit_array_t IS
    VARIABLE temp, temp1 : unsigned(input'length - 1 DOWNTO 0);

    VARIABLE d : digit_array_t := (OTHERS => (OTHERS => '0'));
    VARIABLE idx : INTEGER := 0;
  BEGIN
    temp := input;
    WHILE temp > 0 LOOP
      temp1 := ((temp MOD 10));
      d(100 - idx) := STD_LOGIC_VECTOR(temp1(3 DOWNTO 0));
      temp := temp / 10;
      idx := idx + 1;
    END LOOP;

    RETURN d;
  END FUNCTION;

  FUNCTION string_to_digits(input : STRING) RETURN digit_array_t IS
    VARIABLE temp : digit_array_t := (OTHERS => (OTHERS => '0'));
  BEGIN
    FOR i IN 1 TO input'length - 1 LOOP
      IF input(i) /= '0' THEN
        -- REPORT to_string(to_signed(CHARACTER'pos(input(i)) - CHARACTER'pos('0'), 4));
        temp(i) := STD_LOGIC_VECTOR(to_signed(CHARACTER'pos(input(i)) - CHARACTER'pos('0'), 4));
      END IF;
    END LOOP;

    RETURN temp;
  END FUNCTION;

  FUNCTION digit_to_int(input : digit_array_t) RETURN INTEGER IS
    VARIABLE temp : INTEGER := 0;
  BEGIN

    FOR i IN input'RANGE LOOP
      temp := to_integer(unsigned(input(i))) + temp * 10;
    END LOOP;
    RETURN temp;
  END FUNCTION;
END PACKAGE BODY Utils;