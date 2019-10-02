simulate:
	verilator -Wall -CFLAGS "-std=c++11" -cc Simple.sv -Isource -Mdir verilated --exe ../tests/SimpleTests.cpp
	make -j -C verilated -f VSimple.mk VSimple
	./verilated/VSimple

clean:
	rm -rf verilated
