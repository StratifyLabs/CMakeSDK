
function(cmsdk_bsp_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	cmsdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${CMSDK_SDK_TMP_INSTALL}.elf PARENT_SCOPE)
endfunction()

function(cmsdk_bsp OPTION_LIST HARDWARE_ID START_ADDRESS LIBRARIES)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	cmsdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	cmsdk_internal_arm_arch(${ARCH})

	message(STATUS "CMSDK BSP ${CMSDK_SDK_TMP_TARGET}")

	set(TARGET_NAME ${CMSDK_SDK_TMP_INSTALL}.elf)

	set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build_${CMSDK_SDK_TMP_NO_NAME})

	set_target_properties(${TARGET_NAME}
		PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

	file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

	target_compile_definitions(${TARGET_NAME}
		PUBLIC
		__StratifyOS__
		___${CMSDK_SDK_TMP_CONFIG}
		__${CMSDK_SDK_TMP_OPTION}
		__${ARCH}=__${ARCH}
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
		${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS}
		)

	foreach(LIBRARY ${LIBRARIES})
		target_link_libraries(${TARGET_NAME}
			PRIVATE
			${LIBRARY}_${CONFIG}_${ARCH}
		)
	endforeach()

	get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)

	set(UPDATED_LINK_FLAGS
		-L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR}
		-L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR}
		-Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_INSTALL}.map,--gc-sections,--defsym=_sos_hardware_id=${HARDWARE_ID}
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

	add_custom_target(bin_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJCOPY} -j .boot_hdr -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_INSTALL}.bin)
	add_custom_target(asm_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .boot_hdr -j .tcim -j .text -j .priv_code -j .data -j .bss -j .sysmem -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_INSTALL}.lst)
	add_custom_target(size_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
	add_custom_target(all_${TARGET_NAME} ALL DEPENDS bin_${TARGET_NAME})

endfunction()
