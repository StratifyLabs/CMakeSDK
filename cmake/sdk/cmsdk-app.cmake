function(cmsdk_app_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	cmsdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${CMSDK_SDK_TMP_INSTALL}_${ARCH}.elf PARENT_SCOPE)
endfunction()


function(cmsdk_app OPTION_LIST RAM_SIZE)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	cmsdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	message(STATUS "CMSDK APP ${CMSDK_SDK_TMP_TARGET}")

	set(TARGET_NAME ${CMSDK_SDK_TMP_INSTALL}_${ARCH}.elf)

	set(BINARY_OUTPUT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/build_${CMSDK_SDK_TMP_NO_NAME}_${ARCH})

	set_target_properties(${TARGET_NAME}
		PROPERTIES RUNTIME_OUTPUT_DIRECTORY ${BINARY_OUTPUT_DIR})

	file(MAKE_DIRECTORY ${BINARY_OUTPUT_DIR})

	if(ARCH STREQUAL "link")
		if(CMSDK_IS_WINDOWS OR CMSDK_IS_LINUX)
    	target_link_options(${TARGET_NAME} PRIVATE -static-libstdc++ -static-libgcc)
		endif()

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			___${CMSDK_SDK_TMP_CONFIG}
			__${CMSDK_SDK_TMP_OPTION}
			__${ARCH}
			CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH}
			)

		target_include_directories(${TARGET_NAME}
			PRIVATE
			${CMSDK_LOCAL_PATH}/include/StratifyOS
			)

	else()

		cmsdk_internal_arm_arch(${ARCH})

		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			__StratifyOS__
			__${CMSDK_SDK_TMP_CONFIG}
			__${CMSDK_SDK_TMP_OPTION}
			__${ARCH}
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
			${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS}
			)

		get_target_property(EXIST_LINK_FLAGS ${TARGET_NAME} LINK_FLAGS)
		if(EXIST_LINK_FLAGS STREQUAL "EXIST_LINK_FLAGS-NOTFOUND")
			unset(EXIST_LINK_FLAGS)
		endif()

		set(UPDATED_LINK_FLAGS
			-L${CMSDK_LOCAL_PATH}/arm-none-eabi/lib/${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR}
			-L${CMSDK_LOCAL_PATH}/lib/gcc/arm-none-eabi/${CMAKE_CXX_COMPILER_VERSION}/${CMSDK_ARM_ARCH_BUILD_INSTALL_DIR}/${CMSDK_ARM_ARCH_BUILD_FLOAT_DIR}
			-Wl,--print-memory-usage,-Map,${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_INSTALL}.map,--gc-sections,--defsym=_app_ram_size=${RAM_SIZE}
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
		add_custom_target(asm_${TARGET_NAME} DEPENDS bin_${TARGET_NAME} COMMAND ${CMAKE_OBJDUMP} -S -j .text -j .priv_code -j .data -j .bss -d ${BINARY_OUTPUT_DIR}/${TARGET_NAME} > ${BINARY_OUTPUT_DIR}/${CMSDK_SDK_TMP_INSTALL}.lst)
		add_custom_target(size_${TARGET_NAME} DEPENDS asm_${TARGET_NAME} COMMAND ${CMAKE_SIZE} ${BINARY_OUTPUT_DIR}/${TARGET_NAME})
		add_custom_target(all_${TARGET_NAME} ALL DEPENDS size_${TARGET_NAME})

	endif()

endfunction()


function(cmsdk_app_add_arch_targets OPTION_LIST DEPENDENCIES RAM_SIZE)

	message(STATUS "OPTION LIST ${OPTION_LIST}")
	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)

	if(CMSDK_IS_LINK)

		cmsdk2_add_executable(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}"
			TARGET ${BASE_NAME}
			OPTION ${OPTION}
			CONFIG ${CONFIG}
			ARCH link)

		cmsdk_app("${OPTION_LIST}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			message(STATUS "CMSDK Adding dependency ${DEPENDENCY}_${CONFIG}_link to ${BUILD_TARGET}")

			target_link_libraries(${BUILD_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_link
				)
		endforeach()

		if(CMSDK_SDK_IS_LINUX)
			target_link_libraries(${BUILD_TARGET} PRIVATE pthread rt)
		endif()

	else()

		cmsdk_app_target(BUILD_ARCH ${BASE_NAME} "${OPTION}" "${CONFIG}" ${CMSDK_ARCH})

		foreach (ARCH ${CMSDK_ARCH_LIST})
			cmsdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmsdk_app_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})

				add_executable(${BUILD_TARGET})
				cmsdk_copy_target(
					${BUILD_ARCH_TARGET}
					${BUILD_TARGET}
					)

				# this applies architecture specific options
				cmsdk_app("${BUILD_OPTIONS}" ${RAM_SIZE})

				foreach(DEPENDENCY ${DEPENDENCIES})
					target_link_libraries(${BUILD_TARGET}
						PRIVATE
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${BUILD_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
				endforeach()


			endif()
		endforeach(ARCH)
		cmsdk_app("${BUILD_ARCH_OPTIONS}" ${RAM_SIZE})

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${BUILD_ARCH_TARGET}
				PRIVATE
				${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}
				)
			message(STATUS "${BUILD_ARCH_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")

		endforeach()


	endif()
endfunction()


