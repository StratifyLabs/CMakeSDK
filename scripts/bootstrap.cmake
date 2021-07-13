cmake_minimum_required (VERSION 3.19)

if(NOT SDK_DIRECTORY)
	message(FATAL_ERROR "-DSDK_DIRECTORY=<path> must be supplied before -P")
endif()

option(INSTALL_SL "Download and install SL" OFF)
option(BOOTSTRAP_COMPILER "Install the basic compiler" OFF)


message(STATUS "SDK Directory is ${SDK_DIRECTORY}")

set(SDK_PATH ${SDK_DIRECTORY}/StratifyLabs-SDK)
set(BINARY_PATH ${SDK_PATH}/bin)
set(ENV{SOS_SDK_PATH} ${SDK_PATH})

if(NOT EXISTS ${BINARY_PATH}/sl OR ${INSTALL_SL})

	file(MAKE_DIRECTORY ${BINARY_PATH})

	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin" )
		set(SL_ARCH sl_Darwin_x86_64)
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows" )
		set(SOS_IS_WINDOWS sl_windows_x86_64)
	endif()
	if( ${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux" )
		set(SOS_IS_LINUS sl_linux_x86_64)
	endif()

	# Grab sl and put it in the SDK
	message(STATUS "Downloading ${SL_ARCH} to ${BINARY_PATH}/sl")
	file(DOWNLOAD https://stratifylabs.page.link/${SL_ARCH} ${BINARY_PATH}/sl)
	file(CHMOD ${SDK_PATH}/bin/sl
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


# Check to see if sl is logged in -- abort if it is not

if(NOT EXISTS ${BINARY_PATH}/arm-none-eabi-gcc OR ${BOOTSTRAP_COMPILER})
	message(STATUS "Downloading and installing clean compiler to ${SDK_PATH}")
	execute_process(
		COMMAND ${SDK_PATH}/bin/sl cloud.install:compiler
		)

	set(DEPENDENCIES_DIRECTORY ${SDK_DIRECTORY}/dependencies)
	set(CMAKESDK_DIRECTORY ${DEPENDENCIES_DIRECTORY}/CMakeSDK)
	file(MAKE_DIRECTORY ${CMAKESDK_DIRECTORY}/cmake_arm)

	execute_process(
		COMMAND cmake ..
		WORKING_DIRECTORY ${CMAKESDK_DIRECTORY}/cmake_arm
		)

	execute_process(
		COMMAND cmake --build . --target install
		WORKING_DIRECTORY ${CMAKESDK_DIRECTORY}/cmake_arm
		)

	file(COPY ${CMAKESDK_DIRECTORY}/scripts/profile.sh DESTINATION ${CMAKE_SOURCE_DIR})

	file(MAKE_DIRECTORY ${CMAKE_SOURCE_DIR}/cmake_arm)

endif()

