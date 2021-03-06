VK_C11 = 0

VFLAGS = -Wall\
		 -Isource\
		 -Ibenches\
		 -Mdir verilated

tracer:
	verilator $(VFLAGS)\
		-cc RayTracerTB.sv\
		--exe ../tests/RayTracerTests.cpp ../tests/RayTracer.cpp ../tests/Memory.cpp
	make -j -C verilated -f VRayTracerTB.mk VRayTracerTB
	./verilated/VRayTracerTB

stepper:
	verilator $(VFLAGS)\
		-cc RayStepper.sv\
		--exe ../tests/RayStepperTests.cpp ../tests/RayStepper.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

gen:
	verilator $(VFLAGS)\
		-cc RayGenerator.sv\
		--exe ../tests/RayGenerator.cpp ../tests/RayGeneratorTests.cpp
	make -j -C verilated -f VRayGenerator.mk VRayGenerator
	./verilated/VRayGenerator

memory:
	verilator $(VFLAGS)\
		-cc RayMemoryTB.sv\
		--exe ../tests/RayMemoryTests.cpp ../tests/RayMemory.cpp ../tests/Memory.cpp
	make -j -C verilated -f VRayMemoryTB.mk VRayMemoryTB
	./verilated/VRayMemoryTB

unit:
	verilator $(VFLAGS)\
		-cc RayUnitTB.sv\
		--exe ../tests/RayUnitTests.cpp ../tests/RayUnit.cpp ../tests/Memory.cpp
	make -j -C verilated -f VRayUnitTB.mk VRayUnitTB
	./verilated/VRayUnitTB

look:
	verilator $(VFLAGS)\
		-CFLAGS "$(shell pkg-config --cflags opencv)"\
		-LDFLAGS "$(shell pkg-config --libs opencv)"\
		-cc RayStepper.sv\
		--exe ../tests/Look.cpp ../tests/RayStepper.cpp
	make -j -C verilated -f VRayStepper.mk VRayStepper
	./verilated/VRayStepper

lunit:
	verilator $(VFLAGS)\
		-CFLAGS "$(shell pkg-config --cflags opencv)"\
		-LDFLAGS "$(shell pkg-config --libs opencv)"\
		-cc RayUnitTB.sv\
		--exe ../tests/LookUnit.cpp ../tests/RayUnit.cpp ../tests/Memory.cpp
	make -j -C verilated -f VRayUnitTB.mk VRayUnitTB
	./verilated/VRayUnitTB

ltr:
	verilator $(VFLAGS)\
		-CFLAGS "$(shell pkg-config --cflags opencv)"\
		-LDFLAGS "$(shell pkg-config --libs opencv)"\
		-cc RayTracerTB.sv\
		--exe ../tests/LookTracer.cpp ../tests/RayTracer.cpp ../tests/Memory.cpp
	make -j -C verilated -f VRayTracerTB.mk VRayTracerTB
	./verilated/VRayTracerTB

simple:
	verilator $(VFLAGS)\
		-cc Simple.sv\
		--exe ../tests/Simple.cpp
	make -j -C verilated -f VSimple.mk VSimple
	./verilated/VSimple

clean:
	rm -rf verilated
