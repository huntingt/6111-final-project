VFLAGS = -Wall\
		 -CFLAGS "-std=c++17"\
		 -Isource\
		 -Mdir verilated

stepper:
	verilator $(VFLAGS)\
		-cc RayStepper.sv\
		--exe ../tests/RayStepperTests.cpp ../tests/RayStepper.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

look:
	verilator $(VFLAGS)\
		-CFLAGS "$(shell pkg-config --cflags opencv4)"\
		-LDFLAGS "$(shell pkg-config --libs opencv4)"\
		-cc RayStepper.sv\
		--exe ../tests/Look.cpp ../tests/RayStepper.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

simple:
	verilator $(VFLAGS)\
		-cc Simple.sv\
		--exe ../tests/Simple.cpp
	make -j -C verilated -f VSimple.mk VSimple
	./verilated/VSimple

clean:
	rm -rf verilated
