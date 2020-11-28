# support for the cross compiling to StratifyOS
# Public Domain
#

#################
# System Config #
#################

if(NOT CMAKE_SYSTEM_NAME)
	set(CMAKE_SYSTEM_NAME StratifyOS)
endif()
set(CMAKE_SYSTEM_PROCESSOR arm)
# Represents the name of the specific processor type, e.g. Cortex-M4
if(NOT CPU_NAME)
	set(CPU_NAME generic)
endif()


# StratifyOS does not support shared libs
set_property(GLOBAL PROPERTY TARGET_SUPPORTS_SHARED_LIBS FALSE)

# While StratifyOS doesn't exec elfs directly, the toolchain makes them
set(CMAKE_EXECUTABLE_SUFFIX .elf)

# I forget what these 2 statements do
set(CMAKE_C_LINK_SHARED_LIBRARY )
set(CMAKE_C_LINK_MODULE_LIBRARY )

set(CPU_FLAGS "-ffreestanding")
set(LD_FLAGS "-ffreestanding")
# This is gcc-dependent
# set(LD_FLAGS "--specs=nano.specs --specs=nosys.specs") 
