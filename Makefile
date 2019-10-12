VFLAGS = -Wall\
		 -CFLAGS "-std=c++11"\
		 -Isource\
		 -Mdir verilated

simple:
	verilator $(VFLAGS)\
		-cc Simple.sv\
		--exe ../tests/Simple.cpp
	make -j -C verilated -f VSimple.mk VSimple
	./verilated/VSimple

stepper:
	verilator $(VFLAGS)\
		-cc RayStepper.sv\
		--exe ../tests/RayStepperTests.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

clean:
	rm -rf verilated
