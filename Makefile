VFLAGS = -Wall\
		 -CFLAGS "-std=c++17"\
		 -Isource\
		 -Ibenches\
		 -Mdir verilated

stepper:
	verilator $(VFLAGS)\
		-cc RayStepper.sv\
		--exe ../tests/RayStepperTests.cpp ../tests/RayStepper.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

memory:
	verilator $(VFLAGS)\
		-cc RayMemoryTB.sv\
		--exe ../tests/RayMemoryTests.cpp
	make -j -C verilated -f VRayMemoryTB.mk VRayMemoryTB
	./verilated/VRayMemoryTB

look:
	verilator $(VFLAGS)\
		-CFLAGS "$(shell pkg-config --cflags opencv)"\
		-LDFLAGS "$(shell pkg-config --libs opencv)"\
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
