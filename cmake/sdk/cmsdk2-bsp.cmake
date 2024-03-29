function(cmsdk2_bsp_add_executable)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_bsp_add_executable
    ARGUMENTS ${ARGV}
    REQUIRED TARGET NAME CONFIG ARCH
    ONE_VALUE TARGET TARGET NAME OPTION CONFIG ARCH SUFFIX)

  message(STATUS "CMSDK2 BSP ${ARGS_NAME} option:${ARGS_OPTION} config:${ARGS_CONFIG} arch:${ARGS_ARCH}")
  cmsdk2_internal_build_target_name(
    NAME ${ARGS_NAME}
    OPTION ${ARGS_OPTION}
    CONFIG ${ARGS_CONFIG}
    ARCH ${ARGS_ARCH}
    SUFFIX ${ARGS_SUFFIX}
    RESULT TARGET_NAME_DISCARD
    RESULT_NO_ARCH TARGET_NAME
    BUILD_FOLDER_NO_ARCH TARGET_BUILD_FOLDER)
  add_executable(${TARGET_NAME})
  if(ARGS_OPTION)
    set_target_properties(${TARGET_NAME} PROPERTIES
      CMSDK_PROPERTY_OPTION ${ARGS_OPTION}
      )
  endif()

  set_target_properties(${TARGET_NAME} PROPERTIES
    CMSDK_PROPERTY_NAME ${ARGS_NAME}
    CMSDK_PROPERTY_CONFIG ${ARGS_CONFIG}
    CMSDK_PROPERTY_ARCH ${ARGS_ARCH}
    CMSDK_PROPERTY_BUILD_FOLDER ${TARGET_BUILD_FOLDER})

  set(${ARGS_TARGET} ${TARGET_NAME} PARENT_SCOPE)

endfunction()

function(cmsdk2_bsp_add_dependencies)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_bsp_add_dependencies
    ARGUMENTS ${ARGV}
    REQUIRED TARGET HARDWARE_ID START_ADDRESS
    MULTI_VALUE DEPENDENCIES
    ONE_VALUE TARGET HARDWARE_ID START_ADDRESS)

  cmsdk2_internal_get_target_components(${ARGS_TARGET})
  message(STATUS "CMSDK2 Add BSP Dependencies ${ARGS_TARGET} -> ${NAME} option:${OPTION} config:${CONFIG} arch:${ARCH}")

  if(ARGS_DEPENDENCIES)
    message(STATUS "  ${ARGS_TARGET} -> Save dependencies ${ARGS_DEPENDENCIES}")
    set_target_properties(${ARGS_TARGET} PROPERTIES
      CMSDK_PROPERTY_DEPENDENCIES "${ARGS_DEPENDENCIES}")
  endif()

  cmsdk2_get_arm_arch(
    ARCHITECTURE ${ARCH}
    FLOAT_OPTIONS BUILD_FLOAT_OPTIONS
    FLOAT_DIRECTORY BUILD_FLOAT_DIRECTORY
    INSTALL_DIRECTORY BUILD_INSTALL_DIRECTORY)

  set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_BUILD_FOLDER})

  set_target_properties(${ARGS_TARGET}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

  file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

  target_compile_definitions(${ARGS_TARGET}
    PUBLIC
    __HARDWARE_ID=${ARGS_HARDWARE_ID})
  if(OPTION)
    target_compile_definitions(${ARGS_TARGET}
      PUBLIC
      __${OPTION})
  endif()

  target_include_directories(${ARGS_TARGET}
    PUBLIC
    ${CMSDK_BUILD_SYSTEM_INCLUDES})

  foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
    set(TARGET_LIBRARY ${DEPENDENCY}_${CONFIG}_${ARCH})
    target_link_libraries(${ARGS_TARGET}
      PRIVATE
      ${TARGET_LIBRARY})
    message(STATUS "  ${ARGS_TARGET} -> ${TARGET_LIBRARY}")
  endforeach()

  get_target_property(EXISTING_LINK_FLAGS ${ARGS_TARGET} LINK_FLAGS)

  set(UPDATED_LINK_FLAGS
    -L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${BINARY_OUTPUT_DIR}/${BUILD_FLOAT_DIRECTORY}
    -L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${BINARY_OUTPUT_DIR}/${BUILD_FLOAT_DIRECTORY}
    -Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${NAME}.map,--gc-sections,--defsym=_sos_hardware_id=${ARGS_HARDWARE_ID}
    -Ttext=${ARGS_START_ADDRESS}
    -nostdlib
    -u mcu_core_vector_table
    ${EXISTING_LINK_FLAGS})
  list(JOIN UPDATED_LINK_FLAGS " " LINK_FLAGS)
  set_target_properties(${ARGS_TARGET}
    PROPERTIES
    LINK_FLAGS
    "${LINK_FLAGS}")
  message(STATUS "CMSDK2 BSP BIN target: ${BINARY_OUTPUT_DIR}/${NAME}.bin")
  add_custom_target(bin_${ARGS_TARGET} DEPENDS ${ARGS_TARGET} COMMAND ${CMAKE_OBJCOPY} -j .boot_hdr -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${ARGS_TARGET} ${BINARY_OUTPUT_DIR}/${NAME}.bin)
  message(STATUS "CMSDK2 BSP ASM target: ${BINARY_OUTPUT_DIR}/${NAME}.lst")
  add_custom_target(asm_${ARGS_TARGET} DEPENDS ${ARGS_TARGET} COMMAND ${CMAKE_OBJDUMP} -S -j .boot_hdr -j .tcim -j .text -j .priv_code -j .data -j .bss -j .sysmem -d ${BINARY_OUTPUT_DIR}/${ARGS_TARGET} > ${BINARY_OUTPUT_DIR}/${NAME}.lst)
  add_custom_target(size_${ARGS_TARGET} DEPENDS ${ARGS_TARGET} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${ARGS_TARGET})
  add_custom_target(all_${ARGS_TARGET} ALL DEPENDS bin_${ARGS_TARGET})

endfunction()
