function(cmsdk_library_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	cmsdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${CMSDK_SDK_TMP_TARGET} PARENT_SCOPE)
endfunction()

function(cmsdk_library_add_architecture_targets OPTION_LIST ARCH DEPENDENCIES)
	set(ONE_VALUE_ARGS ARCHITECTURE)
	set(MULTI_VALUE_ARGS TARGET DEPENDENCIES)
	cmake_parse_arguments(
		ARGS "" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )

	message("ARCH is ${ARGS_ARCHITECTURE}")
	message("TARGET is ${ARGS_TARGET}")
	message("DEPS is ${ARGS_DEPENDENCIES}")


	#cmsdk_library_add_arch_targets(${TARGET} ${ARCHITECTURE} "${DEPENDENCIES}")
endfunction()

function(cmsdk_library_add_arch_targets OPTION_LIST ARCH DEPENDENCIES)


	string(COMPARE EQUAL ${ARCH} link IS_LINK)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)

	if(IS_LINK)

		cmsdk_library_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" link)

		cmsdk_library("${OPTION_LIST}")

		foreach(DEPENDENCY ${DEPENDENCIES})

			message(STATUS "CMSDK Adding ${DEPENDENCY}_${CONFIG}_${ARCH} to ${BUILD_TARGET}")

			target_link_libraries(${BUILD_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${ARCH}
				)

		endforeach()

		get_target_property(LIBS ${BUILD_TARGET} LINK_LIBRARIES)

	else()


		cmsdk_library_target(BUILD_ARCH ${BASE_NAME} "${OPTION}" "${CONFIG}" ${CMSDK_ARCH})

		foreach (ARCH ${CMSDK_ARCH_LIST})
			cmsdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmsdk_library_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})


				add_library(${BUILD_TARGET} STATIC)

				cmsdk_copy_target(
					${BUILD_ARCH_TARGET}
					${BUILD_TARGET}
					)

				# this applies architecture specific options
				cmsdk_library("${BUILD_OPTIONS}")

				foreach(DEPENDENCY ${DEPENDENCIES})
					message(STATUS "CMSDK Adding ${DEPENDENCY}_${CONFIG}_${ARCH} to ${BUILD_TARGET}")
					target_link_libraries(${BUILD_TARGET}
						PUBLIC
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${BUILD_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
				endforeach()


			endif()
		endforeach(ARCH)
		cmsdk_library("${BUILD_ARCH_OPTIONS}")

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${BUILD_ARCH_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}
				)
			message(STATUS "${BUILD_ARCH_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
		endforeach()
	endif()
endfunction()

function(cmsdk_library OPTION_LIST)
	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	cmsdk_internal_build_target_name(${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})
	cmsdk_internal_arm_arch(${ARCH})

	message(STATUS "CMSDK Library ${CMSDK_SDK_TMP_TARGET}")

	target_compile_definitions(${CMSDK_SDK_TMP_TARGET}
		PUBLIC
		PRIVATE
		__${ARCH}
		___${CMSDK_SDK_TMP_CONFIG}
		__${CMSDK_SDK_TMP_OPTION}
		MCU_CMSDK_GIT_HASH=${CMSDK_GIT_HASH}
		)

	if(CMSDK_IS_ARM)

		cmsdk_internal_arm_arch(${ARCH})

		target_compile_definitions(${CMSDK_SDK_TMP_TARGET}
			PUBLIC
			__StratifyOS__
			)

		target_compile_options(${CMSDK_SDK_TMP_TARGET}
			PRIVATE
			-mthumb -ffunction-sections -fdata-sections
			${CMSDK_ARM_ARCH_BUILD_FLOAT_OPTIONS}
			)

		set_target_properties(${CMSDK_SDK_TMP_TARGET}
			PROPERTIES NO_SYSTEM_FROM_IMPORTED TRUE
			)

		target_include_directories(${CMSDK_SDK_TMP_TARGET}
			PRIVATE
			${CMSDK_LOCAL_PATH}/arm-none-eabi/include/StratifyOS
			)

	else()
		target_include_directories(${CMSDK_SDK_TMP_TARGET}
			PRIVATE
			${CMSDK_LOCAL_PATH}/include/StratifyOS
			)

	endif()

	get_target_property(TARGET_BINARY_DIR ${CMSDK_SDK_TMP_TARGET} BINARY_DIR)

	install(
		TARGETS ${CMSDK_SDK_TMP_TARGET}
		EXPORT ${CMSDK_SDK_TMP_TARGET}
		DESTINATION lib
		OPTIONAL)
	install(
		EXPORT ${CMSDK_SDK_TMP_TARGET}
		DESTINATION ${CMSDK_LOCAL_PATH}/cmake/targets)

endfunction()
