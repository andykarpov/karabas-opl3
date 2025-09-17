all: testbench_top

testbench_top: IVFLAGS+=-I../rtl/
testbench_top: testbench_top.v ymf262.v ../rtl/top.v

testbench_%:
	iverilog -g2005-sv ${IVFLAGS} -o $@.vvp $^
	vvp $@.vvp
	gtkwave tb.gtkw
	@rm $@.vvp

clean:
	rm -rf *.vcd *.vvp

-include Makefile.local
