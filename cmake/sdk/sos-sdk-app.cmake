function(sos_sdk_app_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	sos_sdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${SOS_SDK_TMP_INSTALL}_${ARCH}.elf PARENT_SCOPE)
endfunction()

function(sos_sdk_app OPTION_LIST RAM_SIZE)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	sos_sdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	message(STATUS "SOS SDK APP ${SOS_SDK_TMP_TARGET}")

	set(TARGET_NAME ${SOS_SDK_TMP_INSTALL}_${ARCH}.elf)

	set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build_${SOS_SDK_TMP_NO_NAME}_${ARCH})

	set_target_properties(${TARGET_NAME}
		PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

	file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

	if(ARCH STREQUAL "link")
    	target_link_options(${TARGET_NAME} PRIVATE -static -static-libstdc++ -static-libgcc)

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			___${SOS_SDK_TMP_CONFIG}
			__${SOS_SDK_TMP_OPTION}
			__${ARCH}
			MCU_SOS_GIT_HASH=${SOS_GIT_HASH}
			)

		target_include_directories(${TARGET_NAME}
			PRIVATE
			${SOS_SDK_PATH}/include/StratifyOS
			)

	else()

		sos_sdk_internal_arm_arch(${ARCH})

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			__StratifyOS__
			__${SOS_SDK_TMP_CONFIG}
			__${SOS_SDK_TMP_OPTION}
			__${ARCH}
			MCU_SOS_GIT_HASH=${SOS_GIT_HASH}
			)

		target_include_directories(${TARGET_NAME}
			PUBLIC
			${SOS_BUILD_SYSTEM_INCLUDES}
			PRIVATE
			${SOS_SDK_PATH}/arm-none-eabi/include/StratifyOS
			)

		target_compile_options(${TARGET_NAME}
			PUBLIC
			-mthumb -mlong-calls -ffunction-sections -fdata-sections
			${SOS_ARM_ARCH_BUILD_FLOAT_OPTIONS}
			)

		get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)
		if(EXIST_LINK_FLAGS STREQUAL "EXIST_LINK_FLAGS-NOTFOUND")
			unset(EXIST_LINK_FLAGS)
		endif()

		set(UPDATED_LINK_FLAGS
			-L${SOS_SDK_PATH}/arm-none-eabi/lib/${SOS_ARM_ARCH_BUILD_INSTALL_DIR}/${SOS_ARM_ARCH_BUILD_FLOAT_DIR}
			-L${SOS_SDK_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${SOS_ARM_ARCH_BUILD_INSTALL_DIR}/${SOS_ARM_ARCH_BUILD_FLOAT_DIR}
			-Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${SOS_SDK_TMP_INSTALL}.map,--gc-sections,--defsym=_app_ram_size=${RAM_SIZE}
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

		add_custom_target(bin_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJCOPY} -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${SOS_SDK_TMP_NO_CONFIG})
		add_custom_target(asm_${TARGET_NAME} DEPENDS bin_${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .text -j .priv_code -j .data -j .bss -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${SOS_SDK_TMP_INSTALL}.lst)
		add_custom_target(size_${TARGET_NAME} DEPENDS asm_${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
		add_custom_target(all_${TARGET_NAME} ALL DEPENDS size_${TARGET_NAME})

	endif()

endfunction()

function(sos_sdk_app_add_arch_targets OPTION_LIST DEPENDENCIES RAM_SIZE)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)

	if(SOS_IS_LINK)

		sos_sdk_app_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" link)

		sos_sdk_app("${OPTION_LIST}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			message(STATUS "SOS SDK Adding dependency ${DEPENDENCY}_${CONFIG}_link to ${BUILD_TARGET}")

			target_link_libraries(${BUILD_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_link
				)
		endforeach()

		if(SOS_SDK_IS_LINUX)
			target_link_libraries(${BUILD_TARGET} PRIVATE pthread)
		endif()

	else()

		sos_sdk_app_target(BUILD_ARCH ${BASE_NAME} "${OPTION}" "${CONFIG}" ${SOS_ARCH})

		foreach (ARCH ${SOS_ARCH_LIST})
			sos_sdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				sos_sdk_app_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})

				add_executable(${BUILD_TARGET})
				sos_sdk_copy_target(
					${BUILD_ARCH_TARGET}
					${BUILD_TARGET}
					)

				# this applies architecture specific options
				sos_sdk_app("${BUILD_OPTIONS}" ${RAM_SIZE})

				foreach(DEPENDENCY ${DEPENDENCIES})
					target_link_libraries(${BUILD_TARGET}
						PRIVATE
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${BUILD_TARGET} -> ${DEPENDENCY}_${CONFIG}_${SOS_ARCH}")
				endforeach()


			endif()
		endforeach(ARCH)
		sos_sdk_app("${BUILD_ARCH_OPTIONS}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${BUILD_ARCH_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_${SOS_ARCH}
				)
			message(STATUS "${BUILD_ARCH_TARGET} -> ${DEPENDENCY}_${CONFIG}_${SOS_ARCH}")

		endforeach()


	endif()
endfunction()
