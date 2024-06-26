function(cmsdk2_add_executable)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_add_executable
    OPTIONS FLAT
    ARGUMENTS ${ARGV}
    REQUIRED TARGET NAME CONFIG ARCH
    ONE_VALUE TARGET NAME OPTION CONFIG ARCH SUFFIX)

  message(STATUS "CMSDK2 APP ${ARGS_NAME} option:${ARGS_OPTION} config:${ARGS_CONFIG} arch:${ARGS_ARCH}")
  if(ARGS_EXTRAS)
    message(STATUS "   extras:${ARGS_EXTRAS}")
  endif()
  if(CMSDK_IS_ARM)
    set(IS_APPEND_ELF ON)
  endif()
  cmsdk2_internal_build_target_name(
    NAME ${ARGS_NAME}
    OPTION ${ARGS_OPTION}
    CONFIG ${ARGS_CONFIG}
    ARCH ${ARGS_ARCH}
    SUFFIX ${ARGS_SUFFIX}
    RESULT TARGET_NAME
    BUILD_FOLDER TARGET_BUILD_FOLDER)
  if(ARGS_FLAT)
    set(TARGET_NAME ${ARGS_NAME})
  endif()
  message(STATUS "  target:${TARGET_NAME}")
  add_executable(${TARGET_NAME})

  if(ARGS_OPTION)
    set_target_properties(${TARGET_NAME} PROPERTIES
      CMSDK_PROPERTY_OPTION ${ARGS_OPTION})
  endif()
  if(ARGS_SUFFIX)
    set_target_properties(${TARGET_NAME} PROPERTIES
      CMSDK_PROPERTY_SUFFIX ${ARGS_SUFFIX})
  endif()
  set_target_properties(${TARGET_NAME} PROPERTIES
    CMSDK_PROPERTY_NAME ${ARGS_NAME}
    CMSDK_PROPERTY_CONFIG ${ARGS_CONFIG}
    CMSDK_PROPERTY_ARCH ${ARGS_ARCH}
    CMSDK_PROPERTY_BUILD_FOLDER ${TARGET_BUILD_FOLDER})

  if(ARGS_OPTION)
    target_compile_definitions(${TARGET_NAME}
      PUBLIC
      __${ARGS_OPTION})
  endif()
  set(${ARGS_TARGET} ${TARGET_NAME} PARENT_SCOPE)
endfunction()

function(cmsdk2_app_update_target_for_architecture)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_app_update_target_for_architecture
    ARGUMENTS ${ARGV}
    REQUIRED TARGET
    ONE_VALUE TARGET RAM_SIZE)

  set(TARGET_NAME ${ARGS_TARGET})
  cmsdk2_internal_get_target_components(${TARGET_NAME})

  set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/${TARGET_BUILD_FOLDER})
  set_target_properties(${TARGET_NAME}
    PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})
  file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})
  target_compile_definitions(${TARGET_NAME}
    PUBLIC
    ___${CONFIG}
    __${ARCH}=__${ARCH}
    CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH})

  if(ARCH STREQUAL "link")
    if(CMSDK_IS_WINDOWS OR CMSDK_IS_LINUX)
      target_link_options(${TARGET_NAME} PRIVATE -static-libstdc++ -static-libgcc)
    endif()
    target_include_directories(${TARGET_NAME}
      PRIVATE
      ${CMSDK_LOCAL_PATH}/include/StratifyOS)
  else()
    # load ARCH specific variables into current scope
    cmsdk2_get_arm_arch(
      ARCHITECTURE ${ARCH}
      FLOAT_OPTIONS BUILD_FLOAT_OPTIONS
      FLOAT_DIRECTORY BUILD_FLOAT_DIRECTORY
      INSTALL_DIRECTORY BUILD_INSTALL_DIRECTORY)
    target_compile_definitions(${TARGET_NAME}
      PUBLIC
      __StratifyOS__)
    target_include_directories(${TARGET_NAME}
      PUBLIC
      ${CMSDK_BUILD_SYSTEM_INCLUDES}
      PRIVATE
      ${CMSDK_LOCAL_PATH}/arm-none-eabi/include/StratifyOS)
    target_compile_options(${TARGET_NAME}
      PUBLIC
      ${BUILD_FLOAT_OPTIONS})
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
      BUILD_FOLDER BUILD_FOLDER)
    set(UPDATED_LINK_FLAGS
      -L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
      -L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
      -Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.map,--gc-sections,--defsym=_app_ram_size=${ARGS_RAM_SIZE}
      -Tldscripts/app.ld
      -nostartfiles
      -nostdlib
      -u crt
      ${EXIST_LINK_FLAGS})
    list(JOIN UPDATED_LINK_FLAGS " " LINK_FLAGS)
    set_target_properties(${TARGET_NAME}
      PROPERTIES
      LINK_FLAGS
      "${LINK_FLAGS}")
    string(REPLACE ${SUFFIX} "" TARGET_NAME_NO_SUFFIX ${TARGET_NAME})
    message(STATUS "CMSDK2 App BIN target: ${BINARY_OUTPUT_DIR}/${TARGET_NAME}")
    message(STATUS "   No Suffix: ${TARGET_NAME_NO_SUFFIX} removed ${SUFFIX}")
    add_custom_target(bin_${TARGET_NAME}
      DEPENDS ${TARGET_NAME}
      COMMAND ${CMAKE_OBJCOPY} -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${TARGET_NAME_NO_SUFFIX})
    message(STATUS "CMSDK2 App ASM target: ${BINARY_OUTPUT_DIR}/${TARGET_NAME_NO_SUFFIX}.lst")
    add_custom_target(size_${TARGET_NAME}
      DEPENDS bin_${TARGET_NAME}
      COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
    add_custom_target(asm_${TARGET_NAME}
      DEPENDS bin_${TARGET_NAME}
      COMMAND ${CMAKE_OBJDUMP} -S -j .text -j .priv_code -j .data -j .bss -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${TARGET_NAME_NO_SUFFIX}.lst)
    add_custom_target(all_${TARGET_NAME} ALL
      DEPENDS size_${TARGET_NAME})
  endif()
endfunction()

function(cmsdk2_app_add_dependencies)
  cmsdk2_internal_parse_arguments(
    INTERNAL_FUNCTION_NAME cmsdk2_app_add_dependencies
    ARGUMENTS ${ARGV}
    MULTI_VALUE DEPENDENCIES TARGETS ARCHITECTURES
    REQUIRED TARGET
    ONE_VALUE TARGET RAM_SIZE)

  if(NOT ARGS_RAM_SIZE)
    set(ARGS_RAM_SIZE 0)
  endif()

  cmsdk2_internal_get_target_components(${ARGS_TARGET})

  if(ARGS_DEPENDENCIES)
    message(STATUS "  ${ARGS_TARGET} -> Save dependencies ${ARGS_DEPENDENCIES}")
    set_target_properties(${ARGS_TARGET} PROPERTIES
      CMSDK_PROPERTY_DEPENDENCIES "${ARGS_DEPENDENCIES}")
  endif()

  if(CMSDK_IS_LINK)
    cmsdk2_app_update_target_for_architecture(
      TARGET ${ARGS_TARGET}
      RAM_SIZE 0)
    foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
      message(STATUS "  ${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
      target_link_libraries(${ARGS_TARGET}
        PRIVATE
        ${DEPENDENCY}_${CONFIG}_${ARCH})
    endforeach()

  else()

    foreach(THIS_ARCH ${ARGS_ARCHITECTURES})
      cmsdk2_internal_is_arch_enabled(
        ARCH ${THIS_ARCH}
        RESULT ARCH_ENABLED)
      if(${ARCH_ENABLED})
        cmsdk2_add_executable(
          TARGET TARGET_NAME
          NAME ${NAME}
          OPTION ${OPTION}
          CONFIG ${CONFIG})

        cmsdk2_copy_target(
          SOURCE ${ARGS_TARGET}
          DESTINATION ${TARGET_NAME})

        # this applies architecture specific options
        cmsdk2_app_update_target_for_architecture(
          TARGET ${TARGET_NAME}
          RAM_SIZE ${ARGS_RAM_SIZE})

        foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
          target_link_libraries(${TARGET_NAME}
            PRIVATE
            ${DEPENDENCY}_${CONFIG}_${THIS_ARCH}
            )
          message(STATUS "  ${TARGET_NAME} -> ${DEPENDENCY}_${CONFIG}_${THIS_ARCH}")
        endforeach()

      endif()
    endforeach()

    cmsdk2_app_update_target_for_architecture(
      TARGET ${ARGS_TARGET}
      RAM_SIZE ${ARGS_RAM_SIZE}
    )

    foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
      target_link_libraries(${ARGS_TARGET}
        PRIVATE
        ${DEPENDENCY}_${CONFIG}_${ARCH}
        )
      message(STATUS "  ${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
    endforeach()
  endif()
endfunction()
