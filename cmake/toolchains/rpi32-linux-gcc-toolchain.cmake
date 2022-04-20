
set(TOOLCHAIN_DIR ${SOS_SDK_PATH})
set(TOOLCHAIN_HOST arm-linux-gnueabihf)
set(TOOLCHAIN_HOST_PREFIX ${TOOLCHAIN_HOST})
set(TOOLCHAIN_BIN_DIR "")

set(TOOLCHAIN_LIB_DIR "${TOOLCHAIN_DIR}/lib" CACHE INTERNAL "GCC TOOLCHAIN LIBRARY DIR")
set(SOS_SDK_LIB_DIR "${TOOLCHAIN_DIR}/lib")

message(STATUS "Use Clang toolchain install dir: " ${TOOLCHAIN_DIR})
set(CMAKE_INSTALL_PREFIX ${TOOLCHAIN_DIR} CACHE INTERNAL "CLANG INSTALL PREFIX")
include_directories(SYSTEM ${TOOLCHAIN_DIR}/include)

set(SOS_SDK_IS_LINUX TRUE CACHE INTERNAL "LINUX BUILD")
set(TOOLCHAIN_C_FLAGS "-D__linux -D__rpi32 -D__processor_arm32" CACHE INTERNAL "CLANG C FLAGS")
set(TOOLCHAIN_CXX_FLAGS "${TOOLCHAIN_C_FLAGS}" CACHE INTERNAL "CLANG CXX FLAGS")

set(CMAKE_FIND_ROOT_PATH  /usr/bin)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)

set(CMAKE_C_COMPILER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}gcc${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN C COMPILER")
set(CMAKE_CXX_COMPILER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}g++${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN C++ COMPILER")
set(CMAKE_ASM_COMPILER ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}g++${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN ASM COMPILER")
set(CMAKE_AR ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}gcc-ar${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN AR")
set(CMAKE_RANLIB ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}gcc-ranlib${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN RANLIB")
set(CMAKE_NM ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}gcc-nm${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN NM")
set(CMAKE_OBJCOPY ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}objcopy${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN OBJCOPY")
set(CMAKE_OBJDUMP ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}objdump${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN OBJDUMP")
set(CMAKE_SIZE ${TOOLCHAIN_BIN_DIR}/${TOOLCHAIN_HOST_PREFIX}size${TOOLCHAIN_EXEC_SUFFIX} CACHE INTERNAL "GCC TOOLCHAIN SIZE")
set(CMAKE_INSTALL_PREFIX ${TOOLCHAIN_DIR}/${TOOLCHAIN_HOST} CACHE INTERNAL "GCC TOOLCHAIN INSTALL PREFIX")

set(CMAKE_C_FLAGS "${TOOLCHAIN_C_FLAGS}")
set(CMAKE_CXX_FLAGS "${TOOLCHAIN_CXX_FLAGS}")


