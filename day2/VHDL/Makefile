GHDL = ghdl
SOURCES = $(wildcard Source/*.vhd)
TESTBENCH = $(wildcard Testbench/*.vhd)
MODULE = -m ghdl

FLAGS= -fsynopsys --std=08 -frelaxed


sim:
	@$(GHDL) -a -O2 -g $(FLAGS) $(SOURCES) $(TESTBENCH)
	@$(GHDL) -e -O2 $(FLAGS) part1_TB
	@$(GHDL) -r $(FLAGS) part1_TB  --wave=wave.ghw --ieee-asserts=disable

clear:
	@$(GHDL) --clean


