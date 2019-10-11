simple:
	verilator -Wall -CFLAGS "-std=c++11"\
		-cc Simple.sv\
		-Isource -Mdir verilated\
		--exe ../tests/Simple.cpp
	make -j -C verilated -f VSimple.mk VSimple
	./verilated/VSimple

clean:
	rm -rf verilated
