function(cmsdk2_app_add_executable)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS TARGET NAME OPTION CONFIG ARCH)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  set(REQUIRED_ARGS TARGET NAME CONFIG ARCH)
  foreach(VALUE ${REQUIRED_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_app_target requires ${VALUE}")
    endif()
  endforeach()

  cmsdk2_internal_build_target_name(
    NAME ${ARGS_NAME}
    OPTION ${ARGS_OPTION}
    CONFIG ${ARGS_CONFIG}
    ARCH ${ARGS_ARCH}
    RESULT TARGET_NAME
    BUILD_FOLDER TARGET_BUILD_FOLDER
  )

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
    CMSDK_PROPERTY_BUILD_FOLDER ${TARGET_BUILD_FOLDER}
    )

  set(${ARGS_TARGET} ${TARGET_NAME} PARENT_SCOPE)

endfunction()

function(cmsdk2_app_add_targets_for_architectures)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS TARGET RAM_SIZE)
  set(MULTI_VALUE_ARGS DEPENDENCIES)
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  foreach(VALUE ${MULTI_VALUE_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_app_add_arch_targets requires ${VALUE}")
    endif()
  endforeach()
  if(NOT ARGS_RAM_SIZE)
    set(ARGS_RAM_SIZE 0)
  endif()

  get_target_property(NAME ${ARGS_TARGET} CMSDK_PROPERTY_NAME)
  get_target_property(CONFIG ${ARGS_TARGET} CMSDK_PROPERTY_CONFIG)
  get_target_property(OPTION ${ARGS_TARGET} CMSDK_PROPERTY_OPTION)
  get_target_property(ARCH ${ARGS_TARGET} CMSDK_PROPERTY_ARCH)

  if(CMSDK_IS_LINK)
    cmsdk2_app_update_target_for_architecture(
      TARGET ${ARGS_TARGET}
      RAM_SIZE 0
    )
    foreach(DEPENDENCY ${DEPENDENCIES})
      message(STATUS "${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")

      target_link_libraries(${ARGS_TARGET}
        PRIVATE
        ${DEPENDENCY}_${CONFIG}_link
        )
    endforeach()

    if(CMSDK_SDK_IS_LINUX)
      target_link_libraries(${ARGS_TARGET} PRIVATE pthread rt)
    endif()

  else()

    foreach(ARCH ${CMSDK_ARCH_LIST})
      cmsdk2_internal_is_arch_enabled(
        ARCH ${ARCH}
        RESULT ARCH_ENABLED)

      if(${ARCH_ENABLED})
        cmsdk2_add_executable(
          TARGET TARGET_NAME
          NAME ${NAME}
          OPTION ${OPTION}
          CONFIG ${ARCH})

        cmsdk2_copy_target(
          SOURCE ${ARGS_TARGET}
          DESTINATION ${TARGET_NAME}
        )

        # this applies architecture specific options
        cmsdk2_update_target_for_architecture(
          TARGET ${TARGET_NAME}
          RAM_SIZE ${ARGS_RAM_SIZE}
        )

        foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
          target_link_libraries(${TARGET_NAME}
            PRIVATE
            ${DEPENDENCY}_${CONFIG}_${ARCH}
            )
          message(STATUS "${TARGET_NAME} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
        endforeach()

      endif()
    endforeach(ARCH)

    cmsdk2_update_target_for_architecture(
      TARGET ${ARGS_TARGET}
      RAM_SIZE ${ARGS_RAM_SIZE}
    )

    foreach(DEPENDENCY ${DEPENDENCIES})
      target_link_libraries(${ARGS_TARGET}
        PRIVATE
        ${DEPENDENCY}_${CONFIG}_${ARCH}
        )
      message(STATUS "${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
    endforeach()
  endif()

endfunction()

function(cmsdk2_app_update_target_for_architecture)
  set(OPTIONS "")
  set(PREFIX ARGS)
  set(ONE_VALUE_ARGS TARGET RAM_SIZE)
  set(MULTI_VALUE_ARGS "")
  cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

  set(REQUIRED_ARGS TARGET)
  foreach(VALUE ${REQUIRED_ARGS})
    if(NOT ARGS_${VALUE})
      message(FATAL_ERROR "cmsdk2_update_target_for_architecture requires ${VALUE}")
    endif()
  endforeach()

  set(TARGET_NAME ${ARGS_TARGET})
  get_target_property(NAME ${TARGET_NAME} CMSDK_PROPERTY_NAME)
  get_target_property(OPTION ${TARGET_NAME} CMSDK_PROPERTY_OPTION)
  get_target_property(CONFIG ${TARGET_NAME} CMSDK_PROPERTY_CONFIG)
  get_target_property(ARCH ${TARGET_NAME} CMSDK_PROPERTY_ARCH)
  get_target_property(TARGET_BUILD_FOLDER ${TARGET_NAME} CMSDK_PROPERTY_BUILD_FOLDER)

  set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_BUILD_FOLDER})

  set_target_properties(${TARGET_NAME}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

  file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

  if(ARCH STREQUAL "link")
    if(CMSDK_IS_WINDOWS OR CMSDK_IS_LINUX)
      target_link_options(${TARGET_NAME} PRIVATE -static-libstdc++ -static-libgcc)
    endif()

    if(OPTION)
      target_compile_definitions(${TARGET_NAME}
        PUBLIC
        __${OPTION}
        )
    endif()

    target_compile_definitions(${TARGET_NAME}
      PUBLIC
      ___${CONFIG}
      __${ARCH}
      CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH}
      )

    target_include_directories(${TARGET_NAME}
      PRIVATE
      ${CMSDK_LOCAL_PATH}/include/StratifyOS
      )

  else()

    # load ARCH specific variables into current scope
    cmsdk2_internal_get_arm_arch(
      ARCHITECTURE ${ARCH}
      FLOAT_OPTIONS BUILD_FLOAT_OPTIONS
      FLOAT_DIRECTORY BUILD_FLOAT_DIRECTORY
      INSTALL_DIRECTORY BUILD_INSTALL_DIRECTORY
    )

    target_compile_definitions(${TARGET_NAME}
      PUBLIC
      __StratifyOS__
      __${CONFIG}
      __${OPTION}
      __${ARGS_ARCH}
      CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH}
      )

    target_include_directories(${TARGET_NAME}
      PUBLIC
      ${CMSDK_BUILD_SYSTEM_INCLUDES}
      PRIVATE
      ${CMSDK_LOCAL_PATH}/arm-none-eabi/include/StratifyOS
      )

    target_compile_options(${TARGET_NAME}
      PUBLIC
      -mthumb -mlong-calls -ffunction-sections -fdata-sections
      ${BUILD_FLOAT_OPTIONS}
      )

    get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)
    if(EXIST_LINK_FLAGS STREQUAL "EXIST_LINK_FLAGS-NOTFOUND")
      unset(EXIST_LINK_FLAGS)
    endif()

    cmsdk2_internal_build_target_name(
      NAME ${NAME}
      OPTION ${OPTION}
      CONFIG ${CONFIG}
      ARCH ${ARCH}
      RESULT INSTALL_NAME
      BUILD_FOLDER BUILD_FOLDER
    )

    set(UPDATED_LINK_FLAGS
      -L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
      -L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
      -Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.map,--gc-sections,--defsym=_app_ram_size=${ARGS_RAM_SIZE}
      -Tldscripts/app.ld
      -nostartfiles
      -nostdlib
      -u crt
      ${EXIST_LINK_FLAGS}
      )

    list(JOIN UPDATED_LINK_FLAGS " " LINK_FLAGS)

    set_target_properties(${TARGET_NAME}
      PROPERTIES
      LINK_FLAGS
      "${LINK_FLAGS}"
      )

    add_custom_target(bin_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJCOPY} -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_NO_CONFIG})
    add_custom_target(asm_${TARGET_NAME} DEPENDS bin_${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .text -j .priv_code -j .data -j .bss -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.lst)
    add_custom_target(size_${TARGET_NAME} DEPENDS asm_${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
    add_custom_target(all_${TARGET_NAME} ALL DEPENDS size_${TARGET_NAME})

  endif()

endfunction()