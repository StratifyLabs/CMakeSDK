function(cmake_sdk_app_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	cmake_sdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${CMAKE_SDK_SDK_TMP_INSTALL}_${ARCH}.elf PARENT_SCOPE)
endfunction()

function(cmake_sdk_app OPTION_LIST RAM_SIZE)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	cmake_sdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	message(STATUS "SOS SDK APP ${CMAKE_SDK_SDK_TMP_TARGET}")

	set(TARGET_NAME ${CMAKE_SDK_SDK_TMP_INSTALL}_${ARCH}.elf)

	set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build_${CMAKE_SDK_SDK_TMP_NO_NAME}_${ARCH})

	set_target_properties(${TARGET_NAME}
		PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

	file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

	if(ARCH STREQUAL "link")
		if(CMAKE_SDK_IS_WINDOWS OR CMAKE_SDK_IS_LINUX)
    	target_link_options(${TARGET_NAME} PRIVATE -static-libstdc++ -static-libgcc)
		endif()

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			___${CMAKE_SDK_SDK_TMP_CONFIG}
			__${CMAKE_SDK_SDK_TMP_OPTION}
			__${ARCH}
			MCU_CMAKE_SDK_GIT_HASH=${CMAKE_SDK_GIT_HASH}
			)

		target_include_directories(${TARGET_NAME}
			PRIVATE
			${CMAKE_SDK_SDK_PATH}/include/StratifyOS
			)

	else()

		cmake_sdk_internal_arm_arch(${ARCH})

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			__StratifyOS__
			__${CMAKE_SDK_SDK_TMP_CONFIG}
			__${CMAKE_SDK_SDK_TMP_OPTION}
			__${ARCH}
			MCU_CMAKE_SDK_GIT_HASH=${CMAKE_SDK_GIT_HASH}
			)

		target_include_directories(${TARGET_NAME}
			PUBLIC
			${CMAKE_SDK_BUILD_SYSTEM_INCLUDES}
			PRIVATE
			${CMAKE_SDK_SDK_PATH}/arm-none-eabi/include/StratifyOS
			)

		target_compile_options(${TARGET_NAME}
			PUBLIC
			-mthumb -mlong-calls -ffunction-sections -fdata-sections
			${CMAKE_SDK_ARM_ARCH_BUILD_FLOAT_OPTIONS}
			)

		get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)
		if(EXIST_LINK_FLAGS STREQUAL "EXIST_LINK_FLAGS-NOTFOUND")
			unset(EXIST_LINK_FLAGS)
		endif()

		set(UPDATED_LINK_FLAGS
			-L${CMAKE_SDK_SDK_PATH}/arm-none-eabi/lib/${CMAKE_SDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMAKE_SDK_ARM_ARCH_BUILD_FLOAT_DIR}
			-L${CMAKE_SDK_SDK_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${CMAKE_SDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMAKE_SDK_ARM_ARCH_BUILD_FLOAT_DIR}
			-Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${CMAKE_SDK_SDK_TMP_INSTALL}.map,--gc-sections,--defsym=_app_ram_size=${RAM_SIZE}
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

		add_custom_target(bin_${TARGET_NAME} DEPENDS ${TARGET_NAME} COMMAND ${CMAKE_OBJCOPY} -j .text -j .data -O binary ${BINARY_OUTPUT_DIR}/${TARGET_NAME} ${BINARY_OUTPUT_DIR}/${CMAKE_SDK_SDK_TMP_NO_CONFIG})
		add_custom_target(asm_${TARGET_NAME} DEPENDS bin_${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .text -j .priv_code -j .data -j .bss -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${CMAKE_SDK_SDK_TMP_INSTALL}.lst)
		add_custom_target(size_${TARGET_NAME} DEPENDS asm_${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
		add_custom_target(all_${TARGET_NAME} ALL DEPENDS size_${TARGET_NAME})

	endif()

endfunction()

function(cmake_sdk_app_add_arch_targets OPTION_LIST DEPENDENCIES RAM_SIZE)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)

	if(CMAKE_SDK_IS_LINK)

		cmake_sdk_app_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" link)

		cmake_sdk_app("${OPTION_LIST}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			message(STATUS "SOS SDK Adding dependency ${DEPENDENCY}_${CONFIG}_link to ${BUILD_TARGET}")

			target_link_libraries(${BUILD_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_link
				)
		endforeach()

		if(CMAKE_SDK_SDK_IS_LINUX)
			target_link_libraries(${BUILD_TARGET} PRIVATE pthread rt)
		endif()

	else()

		cmake_sdk_app_target(BUILD_ARCH ${BASE_NAME} "${OPTION}" "${CONFIG}" ${CMAKE_SDK_ARCH})

		foreach (ARCH ${CMAKE_SDK_ARCH_LIST})
			cmake_sdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmake_sdk_app_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})

				add_executable(${BUILD_TARGET})
				cmake_sdk_copy_target(
					${BUILD_ARCH_TARGET}
					${BUILD_TARGET}
					)

				# this applies architecture specific options
				cmake_sdk_app("${BUILD_OPTIONS}" ${RAM_SIZE})

				foreach(DEPENDENCY ${DEPENDENCIES})
					target_link_libraries(${BUILD_TARGET}
						PRIVATE
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${BUILD_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}")
				endforeach()


			endif()
		endforeach(ARCH)
		cmake_sdk_app("${BUILD_ARCH_OPTIONS}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${BUILD_ARCH_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}
				)
			message(STATUS "${BUILD_ARCH_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}")

		endforeach()


	endif()
endfunction()
