
function(cmsdk2_bsp_add_executable OUTPUT BASE_NAME OPTION CONFIG ARCH)
	set(OPTIONS "")
	set(PREFIX ARGS)
	set(ONE_VALUE_ARGS TARGET NAME OPTION CONFIG ARCH)
	set(MULTI_VALUE_ARGS "")
	cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

	set(REQUIRED_ARGS TARGET NAME CONFIG ARCH)
	foreach(VALUE ${REQUIRED_ARGS})
		if(NOT ARGS_${VALUE})
			message(FATAL_ERROR "cmsdk2_bsp_add_executable requires ${VALUE}")
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

function(cmsdk2_bsp_update_target_for_architecture)
	set(OPTIONS "")
	set(PREFIX ARGS)
	set(ONE_VALUE_ARGS TARGET)
	set(MULTI_VALUE_ARGS DEPENDENCIES)
	cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

	foreach(VALUE ${MULTI_VALUE_ARGS})
		if(NOT ARGS_${VALUE})
			message(FATAL_ERROR "cmsdk2_app_add_arch_targets requires ${VALUE}")
		endif()
	endforeach()

	cmsdk2_internal_build_target_name(
		NAME ${NAME}
		OPTION ${OPTION}
		CONFIG ${CONFIG}
		ARCH ${ARCH}
		RESULT INSTALL_NAME
		BUILD_FOLDER BUILD_FOLDER
	)

	cmsdk2_internal_get_arm_arch(
		ARCHITECTURE ${ARCH}
		FLOAT_OPTIONS BUILD_FLOAT_OPTIONS
		FLOAT_DIRECTORY BUILD_FLOAT_DIRECTORY
		INSTALL_DIRECTORY BUILD_INSTALL_DIRECTORY
	)


	message(STATUS "CMSDK BSP ${CMSDK_SDK_TMP_TARGET}")

	set(TARGET_NAME ${INSTALL_NAME}.elf)

	set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build_${BUILD_FOLDER})

	set_target_properties(${TARGET_NAME}
		PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

	file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

	target_compile_definitions(${TARGET_NAME}
		PUBLIC
		__StratifyOS__
		___${CONFIG}
		__${OPTION}
		__${ARCH}
		__HARDWARE_ID=${HARDWARE_ID}
		CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH}
		)

	target_include_directories(${TARGET_NAME}
		PUBLIC
		${CMSDK_BUILD_SYSTEM_INCLUDES}
		)

	target_compile_options(${TARGET_NAME}
		PUBLIC
		-mthumb -ffunction-sections -fdata-sections
		${BUILD_FLOAT_DIRECTORY}
		)

	foreach(LIBRARY ${LIBRARIES})
		target_link_libraries(${TARGET_NAME}
			PRIVATE
			${LIBRARY}_${CONFIG}_${ARCH}
		)
	endforeach()

	get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)

	set(UPDATED_LINK_FLAGS
		-L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
		-L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${BUILD_INSTALL_DIRECTORY}/${BUILD_FLOAT_DIRECTORY}
		-Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.map,--gc-sections,--defsym=_sos_hardware_id=${HARDWARE_ID}
		-Ttext=${START_ADDRESS}
		-nostdlib
		-u mcu_core_vector_table
		${EXIST_LINK_FLAGS}
		)

	list(JOIN UPDATED_LINK_FLAGS " " LINK_FLAGS)

	set_target_properties(${TARGET_NAME}
		PROPERTIES
		LINK_FLAGS
		"${LINK_FLAGS}"
		)

	add_custom_target(bin_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJCOPY} -j .boot_hdr -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.bin)
	add_custom_target(asm_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .boot_hdr -j .tcim -j .text -j .priv_code -j .data -j .bss -j .sysmem -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${INSTALL_NAME}.lst)
	add_custom_target(size_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
	add_custom_target(all_${TARGET_NAME} ALL DEPENDS bin_${TARGET_NAME})

endfunction()
