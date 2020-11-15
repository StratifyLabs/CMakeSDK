# Configures a toolchain for cross-compiling StratifyOS components
# Public Domain

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
