cmake_minimum_required (VERSION 3.12)

if(NOT SOS_SDK_PATH)
	set(SOS_SDK_PATH $ENV{SOS_SDK_PATH})
endif()

set(CMAKE_MODULE_PATH ${SOS_SDK_PATH}/Tools/gcc/cmake)
set(CMAKE_TOOLCHAIN_FILE ${SOS_SDK_PATH}/Tools/gcc/cmake/sos-toolchain.cmake)

message("MODULE PATHS: ${CMAKE_MODULE_PATH}")

include(sos-sdk)

project(SDK)

set(IS_SDK TRUE CACHE INTERNAL "Build SDK projects")

set(BASE_DIRECTORY ${CMAKE_SOURCE_DIR}/../..)

message(STATUS "Base directory ${BASE_DIRECTORY}")

function(clone_or_pull REPOSITORY BRANCH)
	if(NOT EXISTS ${BASE_DIRECTORY}/${NAME})
		message(STATUS "Need to clone manually for the first call to cmake")
		execute_process(
			COMMAND git clone --branch ${BRANCH} ${REPOSITORY}
			WORKING_DIRECTORY ${BASE_DIRECTORY}
			)
	else()
		execute_process(
			COMMAND git pull
			WORKING_DIRECTORY ${BASE_DIRECTORY}/${NAME}
			)
	endif()
endfunction()


macro(sdk_add_subdirectory NAME BRANCH)
	clone_or_pull(ssh://git@github.com/StratifyLabs/${NAME}.git ${BRANCH})
	add_subdirectory(${BASE_DIRECTORY}/${NAME} ${NAME})
	#	include(${CMAKE_CURRENT_SOURCE_DIR}/../${NAME}/library/${NAME}.cmake)
endmacro()

include(CTest)

clone_or_pull(ssh://git@github.com/StratifyLabs/API.git main)
add_subdirectory(${BASE_DIRECTORY}/API API)
include(${BASE_DIRECTORY}/API/libraries/API.cmake)

sdk_add_subdirectory(StratifyOS developmentv4)

sdk_add_subdirectory(InetAPI main)
sdk_add_subdirectory(CryptoAPI main)
sdk_add_subdirectory(JsonAPI main)
sdk_add_subdirectory(ChartAPI developmentv4)
sdk_add_subdirectory(ReportAPI developmentv4)
sdk_add_subdirectory(CloudAPI developmentv4)
sdk_add_subdirectory(SwdAPI master)
if(SOS_IS_LINK)
	sdk_add_subdirectory(ServiceAPI developmentv4)
	sdk_add_subdirectory(UsbAPI developmentv4)
endif()
sdk_add_subdirectory(SosAPI main)
sdk_add_subdirectory(HalAPI main)
sdk_add_subdirectory(UxAPI main)
if(SOS_IS_ARM)
	sdk_add_subdirectory(ToolboxAPI developmentv4)
endif()



