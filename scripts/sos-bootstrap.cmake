cmake_minimum_required (VERSION 3.18)

if(NOT DEFINED CMSDK_SDK_PATH)
	message(FATAL_ERROR "CMSDK_SDK_PATH must be provided")
endif()

set(DEPENDENCIES_DIRECTORY ${CMSDK_SDK_PATH}/dependencies)
set(SOURCE_DIRECTORY ${DEPENDENCIES_DIRECTORY}/CMakeSDK)
set(LOCAL_PATH ${CMSDK_SDK_PATH}/local)
set(BUILD_DIR cmake_arm)
set(BUILD_DIR_PATH ${SOURCE_DIRECTORY}/${BUILD_DIR})

file(REMOVE_RECURSE ${BUILD_DIR_PATH})
file(MAKE_DIRECTORY ${BUILD_DIR_PATH})

option(INSTALL_SL "Download and install SL" OFF)
option(BOOTSTRAP_COMPILER "Install the basic compiler" OFF)

message(STATUS "SDK Directory is ${CMSDK_SDK_PATH}")

set(BINARY_PATH ${LOCAL_PATH}/bin)
set(ENV{SOS_SDK_PATH} ${LOCAL_PATH})

if(NOT EXISTS ${BINARY_PATH}/sl OR ${INSTALL_SL})

	file(MAKE_DIRECTORY ${BINARY_PATH})

	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin" )
		set(SL_ARCH sl_Darwin_x86_64)
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows" )
		set(SL_ARCH sl_windows_x86_64)
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux" )
		set(SL_ARCH sl_Linux_x86_64)
	endif()

	# Grab sl and put it in the SDK
	message(STATUS "Downloading ${SL_ARCH} to ${BINARY_PATH}/sl")
	file(DOWNLOAD https://stratifylabs.page.link/${SL_ARCH} ${BINARY_PATH}/sl)
	file(CHMOD ${BINARY_PATH}/sl
		PERMISSIONS  OWNER_READ  OWNER_WRITE OWNER_EXECUTE WORLD_READ WORLD_EXECUTE GROUP_READ GROUP_EXECUTE)

endif()

execute_process(
	COMMAND ${BINARY_PATH}/sl user.ping
	RESULT_VARIABLE NOT_LOGGED_IN
	)

if(${NOT_LOGGED_IN})
	message(STATUS "sl is not logged in")
	message(STATUS "To complete the process, use `sl cloud.login` and paste the credential command in the terminal and execute it")
	message(STATUS "Once you are logged in, bootstrap again")
	return()
endif()

if(EXISTS ${BINARY_PATH}/arm-none-eabi-gcc)
	message(STATUS "Compiler is installed at ${BINARY_PATH}")
endif()

if(${BOOTSTRAP_COMPILER})
	message(STATUS "Compiler Bootstrap requested (reinstalling if needed)")
endif()


if(NOT EXISTS ${BINARY_PATH}/arm-none-eabi-gcc OR ${BOOTSTRAP_COMPILER})

	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin" )
		set(COMPILER_ARCH macosx_x86_64)
		set(COMPILER_HASH "60BB5EDFCB9CC3DB3FF409870F6D94BB4E7C084E2D2449499F044B6350641823")
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows" )
		set(COMPILER_ARCH windows_x86_64)
		set(COMPILER_HASH "72BD31854D491DBBC1FD3A4DB9C1E7264E869B727B9BE49EE30C9779FAABF651")
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux" )
		set(COMPILER_ARCH linux_x86_64)
		set(COMPILER_HASH "AF62F9BB76765E9B828F4F69118F10EEBA7530B0E94B5D4376D03A1CCC70EAE4")
	endif()

	set(COMPILER_LINK https://github.com/StratifyLabs/StratifyOS/releases/download/compilerv8/compiler.${COMPILER_ARCH}_sblob)

	message(STATUS "Downloading and installing clean compiler to ${LOCAL_PATH}")

	execute_process(
		COMMAND ${LOCAL_PATH}/bin/sl cloud.install:compiler,url=${COMPILER_LINK},hash=${COMPILER_HASH}
	)

	if(EXISTS ${LOCAL_PATH}/../StratifyLabs-SDK/bin/arm-none-eabi-gcc)
		file(COPY ${LOCAL_PATH}/bin/sl DESTINATION ${LOCAL_PATH}/../StratifyLabs-SDK/bin)
		file(COPY ${LOCAL_PATH}/../StratifyLabs-SDK/ DESTINATION ${LOCAL_PATH}/)
		file(REMOVE_RECURSE ${LOCAL_PATH}/../StratifyLabs-SDK)
	endif()

endif()


file(REMOVE_RECURSE ${SOURCE_DIRECTORY}/cmake_arm)
file(MAKE_DIRECTORY ${SOURCE_DIRECTORY}/cmake_arm)

execute_process(
	COMMAND cmake .. -DCMSDK_LOCAL_PATH=${LOCAL_PATH}
	WORKING_DIRECTORY ${SOURCE_DIRECTORY}/cmake_arm
)

execute_process(
	COMMAND cmake --build . --target install
	WORKING_DIRECTORY ${SOURCE_DIRECTORY}/cmake_arm
)


file(COPY ${SOURCE_DIRECTORY}/scripts/profile.sh DESTINATION ${CMAKE_CURRENT_SOURCE_DIR})
file(REMOVE_RECURSE ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})
file(MAKE_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/${BUILD_DIR})

