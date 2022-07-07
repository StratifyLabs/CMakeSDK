function(cmsdk_internal_get_git_hash)
  execute_process(
    COMMAND git log -1 --format=%h
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    OUTPUT_VARIABLE GIT_HASH_OUTPUT_VARIABLE
    OUTPUT_STRIP_TRAILING_WHITESPACE
    RESULT_VARIABLE RESULT
  )

  if(RESULT)
    set(CMSDK_GIT_HASH "0000000" PARENT_SCOPE)
  else()
    set(CMSDK_GIT_HASH ${GIT_HASH_OUTPUT_VARIABLE} PARENT_SCOPE)
  endif()
endfunction()

macro(cmsdk_internal_startup)
  option(CMSDK_IS_TEST "Build Tests" OFF)
  if(CMAKE_BINARY_DIR MATCHES ".*_link")
    set(CMSDK_BUILD_CONFIG link CACHE INTERNAL "sos build config is link")
    set(CMSDK_ARCH link)
    set(CMSDK_IS_LINK TRUE CACHE INTERNAL "sos is link")
    set(CMSDK_IS_ARM FALSE CACHE INTERNAL "sos is arm")
    set(CMSDK_IS_RPI32 FALSE CACHE INTERNAL "sos is rpi32")
    set(CMSDK_IS_RPI64 FALSE CACHE INTERNAL "sos is rpi64")
    message(STATUS "CMSDK ARCH is link")
  elseif(CMAKE_BINARY_DIR MATCHES ".*_rpi32")
    set(CMSDK_BUILD_CONFIG rpi32 CACHE INTERNAL "sos build config is link")
    set(CMSDK_ARCH link)
    set(CMSDK_IS_LINK TRUE CACHE INTERNAL "sos is link")
    set(CMSDK_IS_ARM FALSE CACHE INTERNAL "sos is arm")
    set(CMSDK_IS_RPI32 TRUE CACHE INTERNAL "sos is rpi32")
    set(CMSDK_IS_RPI64 FALSE CACHE INTERNAL "sos is rpi64")
    set(CMSDK_IS_RPI TRUE CACHE INTERNAL "sos is rpi")
    message(STATUS "CMSDK ARCH is rpi32")
  elseif(CMAKE_BINARY_DIR MATCHES ".*_rpi64")
    set(CMSDK_BUILD_CONFIG rpi64 CACHE INTERNAL "sos build config is rpi64")
    set(CMSDK_ARCH link)
    set(CMSDK_IS_LINK TRUE CACHE INTERNAL "sos is link")
    set(CMSDK_IS_ARM FALSE CACHE INTERNAL "sos is arm")
    set(CMSDK_IS_RPI32 FALSE CACHE INTERNAL "sos is rpi32")
    set(CMSDK_IS_RPI64 TRUE CACHE INTERNAL "sos is rpi64")
    set(CMSDK_IS_RPI TRUE CACHE INTERNAL "sos is rpi")
    message(STATUS "CMSDK ARCH is rpi32")
  elseif(CMAKE_BINARY_DIR MATCHES ".*_arm")
    set(CMSDK_BUILD_CONFIG arm CACHE INTERNAL "sos build config is arm")
    set(CMSDK_IS_ARM TRUE CACHE INTERNAL "sos is arm")
    set(CMSDK_IS_LINK FALSE CACHE INTERNAL "sos is link")

    if(NOT DEFINED CMSDK_ARCH)
      set(CMSDK_ARCH v7m CACHE INTERNAL "Primary ARM Arch")
    endif()

    if(NOT DEFINED CMSDK_ARCH_LIST)
      set(CMSDK_ARCH_LIST v7em v7em_f4sh v7em_f5sh v7em_f5dh CACHE INTERNAL "Additional ARM architectures")
    endif()

    message(STATUS "CMSDK ARCH is arm")
  else()
    message(FATAL_ERROR "No Configuration available build in *_link or *_arm directory")
  endif()

  if(NOT CMSDK_PATH)
    message(FATAL "Must use '-DCMSDK_PATH=<path>'")
  endif()

  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Darwin")
    set(CMSDK_IS_MACOS TRUE CACHE INTERNAL "MAC OS")
  endif()
  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Windows")
    set(CMSDK_IS_WINDOWS TRUE CACHE INTERNAL "Windows OS")
  endif()
  if(${CMAKE_HOST_SYSTEM_NAME} STREQUAL "Linux")
    set(CMSDK_IS_LINUS TRUE CACHE INTERNAL "Linux OS")
    set(CMSDK_IS_LINUX TRUE CACHE INTERNAL "Linux OS")
  endif()

  set(CMSDK_SDK_EXEC_SUFFIX "")
  if(CMSDK_IS_WINDOWS)
    set(CMSDK_SDK_EXEC_SUFFIX ".exe")
  endif()
  set(CMSDK_SDK_GIT_EXEC git${CMSDK_SDK_EXEC_SUFFIX})

  if(CMSDK_VERBOSE)
    set(CMAKE_VERBOSE_MAKEFILE 1)
  endif()

  list(APPEND CMAKE_MODULE_PATH
    ${CMSDK_PATH}/cmake/targets
    ${CMSDK_PATH}/arm-none-eabi/cmake
    ${CMSDK_PATH}/arm-none-eabi/cmake/targets
    )

  cmsdk_internal_get_git_hash()
endmacro()

macro(cmsdk_internal_build_target_name BASE_NAME OPTION_NAME CONFIG_NAME ARCH_NAME)
  set(CMSDK_SDK_TMP_TARGET ${BASE_NAME})
  set(CMSDK_SDK_TMP_INSTALL ${BASE_NAME})
  set(CMSDK_SDK_TMP_NO_CONFIG ${BASE_NAME})
  set(CMSDK_SDK_TMP_NO_NAME "")

  string(COMPARE EQUAL "${OPTION_NAME}" "" OPTION_MISSING)

  if(NOT OPTION_MISSING)
    set(CMSDK_SDK_TMP_OPTION ${OPTION_NAME})
    set(CMSDK_SDK_TMP_TARGET ${CMSDK_SDK_TMP_TARGET}_${CMSDK_SDK_TMP_OPTION})
    set(CMSDK_SDK_TMP_NO_CONFIG ${CMSDK_SDK_TMP_NO_CONFIG}_${CMSDK_SDK_TMP_OPTION})
    set(CMSDK_SDK_TMP_INSTALL ${CMSDK_SDK_TMP_INSTALL}_${CMSDK_SDK_TMP_OPTION})
    set(CMSDK_SDK_TMP_NO_NAME ${OPTION_NAME}_)
  else()
    set(CMSDK_SDK_TMP_OPTION "CMSDK_SDK_OPTION_EMPTY")
  endif()

  if(NOT CONFIG_NAME STREQUAL "__none__")
    set(CMSDK_SDK_TMP_CONFIG ${CONFIG_NAME})
  else()
    set(CMSDK_SDK_TMP_CONFIG "release")
  endif()

  set(CMSDK_SDK_TMP_INSTALL ${CMSDK_SDK_TMP_INSTALL}_${CMSDK_SDK_TMP_CONFIG})

  set(CMSDK_SDK_TMP_TARGET ${CMSDK_SDK_TMP_TARGET}_${CMSDK_SDK_TMP_CONFIG})
  set(CMSDK_SDK_TMP_NO_NAME ${CMSDK_SDK_TMP_NO_NAME}${CMSDK_SDK_TMP_CONFIG})

  if(NOT ARCH_NAME STREQUAL "")
    set(CMSDK_SDK_TMP_TARGET ${CMSDK_SDK_TMP_TARGET}_${ARCH_NAME})
  else()
    message(FATAL " CMSDK ARCH cannot be empty")
  endif()

endmacro()

macro(cmsdk_internal_arm_arch ARCH_NAME)

  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7M -march=armv7-m -DARM_MATH_CM3=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM -march=armv7e-m -DARM_MATH_CM4=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F4SS -march=armv7e-m -mfloat-abi=soft -mfpu=fpv4-sp-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM4=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F4SH -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM4=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5SS -march=armv7e-m -mfloat-abi=soft -mfpu=fpv4-sp-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM4=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5SH -march=armv7e-m -mfloat-abi=hard -mfpu=fpv4-sp-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM4=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5DS -march=armv7e-m -mfloat-abi=soft -mfpu=fpv5-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM7=1)
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5DH -march=armv7e-m -mfloat-abi=hard -mfpu=fpv5-d16 -U__SOFTFP__ -D__FPU_PRESENT=1 -DARM_MATH_CM7=1)

  set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7M ".")
  set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM ".")

  string(COMPARE EQUAL "${CMAKE_C_COMPILER_VERSION}" 9.3.1 IS_GCC_9)
  string(COMPARE EQUAL "${CMAKE_C_COMPILER_VERSION}" 8.3.1 IS_GCC_8)
  string(COMPARE EQUAL "${CMAKE_CXX_COMPILER_VERSION}" 9.3.1 IS_GCC_9XX)
  string(COMPARE EQUAL "${CMAKE_CXX_COMPILER_VERSION}" 8.3.1 IS_GCC_8XX)
  if(IS_GCC_9 OR IS_GCC_8 OR IS_GCC_9XX OR IS_GCC_8XX)
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SS "softfp") #single precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SH "hard")   #single precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SS "softfp") #single precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SH "hard")   #single precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DS "softfp")    #double precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DH "hard")      #double precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7M "thumb/v7-m/nofp") #M3 no FP
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM "thumb/v7e-m/nofp") #M4 no FP
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7_FP "thumb/v7+fp") #M4 with FP
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_DP "thumb/v7e-m+dp") #M7
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_FP "thumb/v7e-m+fp") #m7
  else()
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SS "fpv4-sp/softfp") #single precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SH "fpv4-sp/hard")   #single precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SS "fpv5-sp/softfp") #single precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SH "fpv5-sp/hard")   #single precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DS "fpv5/softfp")    #double precision soft ABI
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DH "fpv5/hard")      #double precision hard ABI
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7M "thumb/v7-m")         #thumb ARMV7M
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM "thumb/v7e-m")       #thumb ARMV7EM
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7_FP "thumb/v7e-m")
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_DP "thumb/v7e-m")       #thumb ARMV7EM
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_FP "thumb/v7e-m")       #thumb ARMV7EM
  endif()

  string(COMPARE EQUAL "${ARCH_NAME}" v7m IS_V7M)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em IS_V7EM)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f4ss IS_V7EM_F4SS)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f4sh IS_V7EM_F4SH)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f5ss IS_V7EM_F5SS)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f5sh IS_V7EM_F5SH)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f5ds IS_V7EM_F5DS)
  string(COMPARE EQUAL "${ARCH_NAME}" v7em_f5dh IS_V7EM_F5DH)

  if(IS_V7M) #armv7m soft float
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7M})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7M})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7M})
  elseif(IS_V7EM) #armv7em soft float
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM})
  elseif(IS_V7EM_F4SS) #armv7em fpu4 single precision soft abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7_FP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SS})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F4SS})
  elseif(IS_V7EM_F4SH) #armv7em fpu4 single precision hard abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7_FP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F4SH})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F4SH})
  elseif(IS_V7EM_F5SS) #armv7em fpu5 single precision soft abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_FP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SS})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5SS})
  elseif(IS_V7EM_F5SH) #armv7em fpu5 single precision hard abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_FP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5SH})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5SH})
  elseif(IS_V7EM_F5DS) #armv7em fpu5 double precision soft abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_DP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DS})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5DS})
  elseif(IS_V7EM_F5DH) #armv7em fpu5 double precision hard abi
    set(CMSDK_ARM_ARCH_BUILD_INSTALL_DIR ${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR_V7EM_DP})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_DIR ${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR_V7EM_F5DH})
    set(CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS ${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS_V7EM_F5DH})
  endif()

  set(CMSDK_BUILD_SYSTEM_INCLUDES
    ${CMAKE_INSTALL_PREFIX}/../lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/include
    ${CMAKE_INSTALL_PREFIX}/../lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/include-fixed
    ${CMAKE_INSTALL_PREFIX}/include
    ${CMAKE_INSTALL_PREFIX}/include/c++/${CMAKE_CXX_COMPILER_VERSION}
    ${CMAKE_INSTALL_PREFIX}/include/c++/${CMAKE_CXX_COMPILER_VERSION}/arm-none-eabi
    )

endmacro()

macro(cmsdk_internal_is_arch_enabled ARCH)
  SET(ARCH_ENABLED OFF)
  cmsdk_internal_arm_arch(${ARCH})

  if(CMSDK_ARCH_ARM_ALL)
    set(ARCH_ENABLED ON)
  else()
    if((IS_V7M) AND (CMSDK_ARCH_ARM_V7M))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM) AND (CMSDK_ARCH_ARM_V7EM))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F4SH) AND (CMSDK_ARCH_ARM_V7EM_F4SH))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F5SH) AND (CMSDK_ARCH_ARM_V7EM_F5SH))
      set(ARCH_ENABLED ON)
    endif()
    if((IS_V7EM_F5DH) AND (CMSDK_ARCH_ARM_V7EM_F5DH))
      set(ARCH_ENABLED ON)
    endif()
  endif()
endmacro()

macro(cmsdk_internal_shared_properties)
  set(CMSDK_SHARED_PROPERTIES
    ADDITIONAL_CLEAN_FILE
    ADDITIONAL_CLEAN_FILES
    ADDITIONAL_MAKE_CLEAN_FILES
    ADVANCED
    AIX_EXPORT_ALL_SYMBOLS
    ALIASED_TARGET
    ALLOW_DUPLICATE_CUSTOM_TARGETS
    ANDROID_ANT_ADDITIONAL_OPTIONS
    ANDROID_API
    ANDROID_API_MIN
    ANDROID_ARCH
    ANDROID_ASSETS_DIRECTORIES
    ANDROID_GUI
    ANDROID_JAR_DEPENDENCIES
    ANDROID_JAR_DIRECTORIES
    ANDROID_NATIVE_LIB_DEPENDENCIES
    ANDROID_NATIVE_LIB_DIRECTORIES
    ANDROID_PROCESS_MAX
    ANDROID_PROGUARD
    ANDROID_PROGUARD_CONFIG_PATH
    ANDROID_SECURE_PROPS_PATH
    ANDROID_SKIP_ANT_STEP
    ANDROID_STL_TYPE
    ARCHIVE_OUTPUT_DIRECTORY
    ARCHIVE_OUTPUT_DIRECTORY_<CONFIG>
    ATTACHED_FILES
    ATTACHED_FILES_ON_FAIL
    AUTOGEN_BUILD_DIR
    AUTOGEN_ORIGIN_DEPENDS
    AUTOGEN_PARALLEL
    AUTOGEN_SOURCE_GROUP
    AUTOGEN_TARGETS_FOLDER
    AUTOGEN_TARGET_DEPENDS
    AUTOMOC
    AUTOMOC_COMPILER_PREDEFINES
    AUTOMOC_DEPEND_FILTERS
    AUTOMOC_EXECUTABLE
    AUTOMOC_MACRO_NAMES
    AUTOMOC_MOC_OPTIONS
    AUTOMOC_PATH_PREFIX
    AUTOMOC_SOURCE_GROUP
    AUTOMOC_TARGETS_FOLDER
    AUTORCC
    AUTORCC_EXECUTABLE
    AUTORCC_OPTIONS
    AUTORCC_OPTIONS
    AUTORCC_SOURCE_GROUP
    AUTOUIC
    AUTOUIC_EXECUTABLE
    AUTOUIC_OPTIONS
    AUTOUIC_OPTIONS
    AUTOUIC_SEARCH_PATHS
    BINARY_DIR
    BINARY_DIR
    BUILDSYSTEM_TARGETS
    BUILD_RPATH
    BUILD_RPATH_USE_ORIGIN
    BUILD_WITH_INSTALL_RPATH
    BUNDLE
    BUNDLE_EXTENSION
    CACHE_VARIABLES
    CLEAN_NO_CUSTOM
    CMAKE_CONFIGURE_DEPENDS
    CMAKE_CUDA_KNOWN_FEATURES
    CMAKE_CXX_KNOWN_FEATURES
    CMAKE_C_KNOWN_FEATURES
    CMAKE_ROLE
    COMMON_LANGUAGE_RUNTIME
    COMPATIBLE_INTERFACE_BOOL
    COMPATIBLE_INTERFACE_NUMBER_MAX
    COMPATIBLE_INTERFACE_NUMBER_MIN
    COMPATIBLE_INTERFACE_STRING
    COMPILE_DEFINITIONS
    COMPILE_DEFINITIONS
    COMPILE_DEFINITIONS
    COMPILE_DEFINITIONS_<CONFIG>
    COMPILE_DEFINITIONS_<CONFIG>
    COMPILE_DEFINITIONS_<CONFIG>
    COMPILE_FEATURES
    COMPILE_FLAGS
    COMPILE_FLAGS
    COMPILE_OPTIONS
    COMPILE_OPTIONS
    COMPILE_OPTIONS
    COMPILE_PDB_OUTPUT_DIRECTORY
    COMPILE_PDB_OUTPUT_DIRECTORY_<CONFIG>
    COST
    CPACK_DESKTOP_SHORTCUTS
    CPACK_NEVER_OVERWRITE
    CPACK_PERMANENT
    CPACK_STARTUP_SHORTCUTS
    CPACK_START_MENU_SHORTCUTS
    CPACK_WIX_ACL
    CROSSCOMPILING_EMULATOR
    CUDA_EXTENSIONS
    CUDA_PTX_COMPILATION
    CUDA_RESOLVE_DEVICE_SYMBOLS
    CUDA_RUNTIME_LIBRARY
    CUDA_SEPARABLE_COMPILATION
    CUDA_STANDARD
    CUDA_STANDARD_REQUIRED
    CXX_EXTENSIONS
    CXX_STANDARD
    CXX_STANDARD_REQUIRED
    C_EXTENSIONS
    C_STANDARD
    C_STANDARD_REQUIRED
    DEBUG_CONFIGURATIONS
    DEBUG_POSTFIX
    DEFINE_SYMBOL
    DEFINITIONS
    DEPENDS
    DEPLOYMENT_ADDITIONAL_FILES
    DEPLOYMENT_REMOTE_DIRECTORY
    DEPRECATION
    DISABLED
    DISABLED_FEATURES
    DISABLE_PRECOMPILE_HEADERS
    DOTNET_TARGET_FRAMEWORK
    DOTNET_TARGET_FRAMEWORK_VERSION
    ECLIPSE_EXTRA_CPROJECT_CONTENTS
    ECLIPSE_EXTRA_NATURES
    ENABLED_FEATURES
    ENABLED_LANGUAGES
    ENABLE_EXPORTS
    ENVIRONMENT
    EXCLUDE_FROM_ALL
    EXCLUDE_FROM_ALL
    EXCLUDE_FROM_DEFAULT_BUILD
    EXCLUDE_FROM_DEFAULT_BUILD_<CONFIG>
    EXPORT_PROPERTIES
    EXTERNAL_OBJECT
    EchoString
    FAIL_REGULAR_EXPRESSION
    FIND_LIBRARY_USE_LIB32_PATHS
    FIND_LIBRARY_USE_LIB64_PATHS
    FIND_LIBRARY_USE_LIBX32_PATHS
    FIND_LIBRARY_USE_OPENBSD_VERSIONING
    FIXTURES_CLEANUP
    FIXTURES_REQUIRED
    FIXTURES_SETUP
    FOLDER
    FRAMEWORK
    FRAMEWORK_VERSION
    Fortran_FORMAT
    Fortran_FORMAT
    Fortran_MODULE_DIRECTORY
    GENERATED
    GENERATOR_FILE_NAME
    GENERATOR_IS_MULTI_CONFIG
    GHS_INTEGRITY_APP
    GHS_NO_SOURCE_GROUP_FILE
    GLOBAL_DEPENDS_DEBUG_MODE
    GLOBAL_DEPENDS_NO_CYCLES
    GNUtoMS
    HAS_CXX
    HEADER_FILE_ONLY
    HELPSTRING
    IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
    IMPLICIT_DEPENDS_INCLUDE_TRANSFORM
    IMPORTED
    IMPORTED_COMMON_LANGUAGE_RUNTIME
    IMPORTED_CONFIGURATIONS
    IMPORTED_IMPLIB
    IMPORTED_LINK_DEPENDENT_LIBRARIES
    IMPORTED_LINK_INTERFACE_LANGUAGES
    IMPORTED_LINK_INTERFACE_LIBRARIES
    IMPORTED_LINK_INTERFACE_MULTIPLICITY
    IMPORTED_OBJECTS
    IMPORT_PREFIX
    IMPORT_SUFFIX
    INCLUDE_DIRECTORIES
    INCLUDE_REGULAR_EXPRESSION
    INSTALL_REMOVE_ENVIRONMENT_RPATH
    INSTALL_RPATH
    INSTALL_RPATH_USE_LINK_PATH
    INTERFACE_AUTOUIC_OPTIONS
    INTERFACE_COMPILE_DEFINITIONS
    INTERFACE_COMPILE_FEATURES
    INTERFACE_COMPILE_OPTIONS
    INTERFACE_INCLUDE_DIRECTORIES
    INTERFACE_LINK_DEPENDS
    INTERFACE_LINK_DIRECTORIES
    INTERFACE_LINK_LIBRARIES
    INTERFACE_LINK_OPTIONS
    INTERFACE_POSITION_INDEPENDENT_CODE
    INTERFACE_PRECOMPILE_HEADERS
    INTERFACE_SOURCES
    INTERFACE_SYSTEM_INCLUDE_DIRECTORIES
    INTERPROCEDURAL_OPTIMIZATION
    INTERPROCEDURAL_OPTIMIZATION
    INTERPROCEDURAL_OPTIMIZATION_<CONFIG>
    INTERPROCEDURAL_OPTIMIZATION_<CONFIG>
    IN_TRY_COMPILE
    IOS_INSTALL_COMBINED
    JOB_POOLS
    JOB_POOL_COMPILE
    JOB_POOL_LINK
    JOB_POOL_PRECOMPILE_HEADER
    KEEP_EXTENSION
    LABELS
    LANGUAGE
    LIBRARY_OUTPUT_DIRECTORY
    LIBRARY_OUTPUT_DIRECTORY_<CONFIG>
    LINKER_LANGUAGE
    LINK_DEPENDS
    LINK_DEPENDS_NO_SHARED
    LINK_DIRECTORIES
    LINK_DIRECTORIES
    LINK_FLAGS
    LINK_FLAGS_<CONFIG>
    LINK_INTERFACE_LIBRARIES
    LINK_INTERFACE_MULTIPLICITY
    LINK_LIBRARIES
    LINK_OPTIONS
    LINK_OPTIONS
    LINK_SEARCH_END_STATIC
    LINK_SEARCH_START_STATIC
    LINK_WHAT_YOU_USE
    LISTFILE_STACK
    MACHO_COMPATIBILITY_VERSION
    MACHO_CURRENT_VERSION
    MACROS
    MANUALLY_ADDED_DEPENDENCIES
    MEASUREMENT
    MODIFIED
    NO_SYSTEM_FROM_IMPORTED
    OBJCXX_EXTENSIONS
    OBJCXX_STANDARD
    OBJCXX_STANDARD_REQUIRED
    OBJC_EXTENSIONS
    OBJC_STANDARD
    OBJC_STANDARD_REQUIRED
    OBJECT_DEPENDS
    OBJECT_OUTPUTS
    OSX_ARCHITECTURES
    OSX_ARCHITECTURES_<CONFIG>
    PACKAGES_FOUND
    PACKAGES_NOT_FOUND
    PARENT_DIRECTORY
    PASS_REGULAR_EXPRESSION
    PDB_NAME
    PDB_NAME_<CONFIG>
    PDB_OUTPUT_DIRECTORY
    PDB_OUTPUT_DIRECTORY_<CONFIG>
    POSITION_INDEPENDENT_CODE
    POST_INSTALL_SCRIPT
    PRECOMPILE_HEADERS
    PRECOMPILE_HEADERS_REUSE_FROM
    PREDEFINED_TARGETS_FOLDER
    PREFIX
    PRE_INSTALL_SCRIPT
    PRIVATE_HEADER
    PROCESSORS
    PROCESSOR_AFFINITY
    PROJECT_LABEL
    PUBLIC_HEADER
    REPORT_UNDEFINED_PROPERTIES
    REQUIRED_FILES
    RESOURCE
    RESOURCE_GROUPS
    RESOURCE_LOCK
    RULE_LAUNCH_COMPILE
    RULE_LAUNCH_COMPILE
    RULE_LAUNCH_COMPILE
    RULE_LAUNCH_CUSTOM
    RULE_LAUNCH_CUSTOM
    RULE_LAUNCH_CUSTOM
    RULE_LAUNCH_LINK
    RULE_LAUNCH_LINK
    RULE_LAUNCH_LINK
    RULE_MESSAGES
    RUNTIME_OUTPUT_DIRECTORY
    RUNTIME_OUTPUT_DIRECTORY_<CONFIG>
    RUN_SERIAL
    SKIP_AUTOGEN
    SKIP_AUTOMOC
    SKIP_AUTORCC
    SKIP_AUTOUIC
    SKIP_BUILD_RPATH
    SKIP_PRECOMPILE_HEADERS
    SKIP_REGULAR_EXPRESSION
    SKIP_RETURN_CODE
    SKIP_UNITY_BUILD_INCLUSION
    SOURCES
    SOURCE_DIR
    SOURCE_DIR
    SOVERSION
    STATIC_LIBRARY_FLAGS
    STATIC_LIBRARY_FLAGS_<CONFIG>
    STATIC_LIBRARY_OPTIONS
    STRINGS
    SUBDIRECTORIES
    SUFFIX
    SYMBOLIC
    TARGET_ARCHIVES_MAY_BE_SHARED_LIBS
    TARGET_MESSAGES
    TARGET_SUPPORTS_SHARED_LIBS
    TESTS
    TEST_INCLUDE_FILE
    TEST_INCLUDE_FILES
    TIMEOUT
    TIMEOUT_AFTER_MATCH
    UNITY_BUILD
    UNITY_BUILD_BATCH_SIZE
    UNITY_BUILD_CODE_AFTER_INCLUDE
    UNITY_BUILD_CODE_BEFORE_INCLUDE
    USE_FOLDERS
    VALUE
    VARIABLES
    VERSION
    VISIBILITY_INLINES_HIDDEN
    WILL_FAIL
    WIN32_EXECUTABLE
    WINDOWS_EXPORT_ALL_SYMBOLS
    WORKING_DIRECTORY
    WRAP_EXCLUDE
    )
endmacro()



