function(cmake_sdk_library_target OUTPUT BASE_NAME OPTION CONFIG ARCH)
	cmake_sdk_internal_build_target_name("${BASE_NAME}" "${OPTION}" "${CONFIG}" "${ARCH}")
	set(${OUTPUT}_OPTIONS "${BASE_NAME};${OPTION};${CONFIG};${ARCH}" PARENT_SCOPE)
	set(${OUTPUT}_TARGET ${CMAKE_SDK_SDK_TMP_TARGET} PARENT_SCOPE)
endfunction()

function(cmake_sdk_library_add_architecture_targets OPTION_LIST ARCH DEPENDENCIES)
	set(ONE_VALUE_ARGS ARCHITECTURE)
	set(MULTI_VALUE_ARGS TARGET DEPENDENCIES)
	cmake_parse_arguments(
		ARGS "" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}" ${ARGN} )

	message("ARCH is ${ARGS_ARCHITECTURE}")
	message("TARGET is ${ARGS_TARGET}")
	message("DEPS is ${ARGS_DEPENDENCIES}")


	#cmake_sdk_library_add_arch_targets(${TARGET} ${ARCHITECTURE} "${DEPENDENCIES}")
endfunction()

function(cmake_sdk_library_add_arch_targets OPTION_LIST ARCH DEPENDENCIES)


	string(COMPARE EQUAL ${ARCH} link IS_LINK)

	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)

	if(IS_LINK)

		cmake_sdk_library_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" link)

		cmake_sdk_library("${OPTION_LIST}")

		foreach(DEPENDENCY ${DEPENDENCIES})

			message(STATUS "SOS SDK Adding ${DEPENDENCY}_${CONFIG}_${ARCH} to ${BUILD_TARGET}")

			target_link_libraries(${BUILD_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${ARCH}
				)

		endforeach()

		get_target_property(LIBS ${BUILD_TARGET} LINK_LIBRARIES)

	else()


		cmake_sdk_library_target(BUILD_ARCH ${BASE_NAME} "${OPTION}" "${CONFIG}" ${CMAKE_SDK_ARCH})

		foreach (ARCH ${CMAKE_SDK_ARCH_LIST})
			cmake_sdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmake_sdk_library_target(BUILD ${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})


				add_library(${BUILD_TARGET} STATIC)

				cmake_sdk_copy_target(
					${BUILD_ARCH_TARGET}
					${BUILD_TARGET}
					)

				# this applies architecture specific options
				cmake_sdk_library("${BUILD_OPTIONS}")

				foreach(DEPENDENCY ${DEPENDENCIES})
					message(STATUS "SOS SDK Adding ${DEPENDENCY}_${CONFIG}_${ARCH} to ${BUILD_TARGET}")
					target_link_libraries(${BUILD_TARGET}
						PUBLIC
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${BUILD_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}")
				endforeach()


			endif()
		endforeach(ARCH)
		cmake_sdk_library("${BUILD_ARCH_OPTIONS}")

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${BUILD_ARCH_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}
				)
			message(STATUS "${BUILD_ARCH_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMAKE_SDK_ARCH}")
		endforeach()
	endif()
endfunction()

function(cmake_sdk_library OPTION_LIST)
	list(GET OPTION_LIST 0 BASE_NAME)
	list(GET OPTION_LIST 1 OPTION)
	list(GET OPTION_LIST 2 CONFIG)
	list(GET OPTION_LIST 3 ARCH)

	cmake_sdk_internal_build_target_name(${BASE_NAME} "${OPTION}" "${CONFIG}" ${ARCH})
	cmake_sdk_internal_arm_arch(${ARCH})

	message(STATUS "SOS SDK Library ${CMAKE_SDK_SDK_TMP_TARGET}")

	target_compile_definitions(${CMAKE_SDK_SDK_TMP_TARGET}
		PUBLIC
		PRIVATE
		__${ARCH}
		___${CMAKE_SDK_SDK_TMP_CONFIG}
		__${CMAKE_SDK_SDK_TMP_OPTION}
		MCU_CMAKE_SDK_GIT_HASH=${CMAKE_SDK_GIT_HASH}
		)

	if(CMAKE_SDK_IS_ARM)

		cmake_sdk_internal_arm_arch(${ARCH})

		target_compile_definitions(${CMAKE_SDK_SDK_TMP_TARGET}
			PUBLIC
			__StratifyOS__
			)

		target_compile_options(${CMAKE_SDK_SDK_TMP_TARGET}
			PRIVATE
			-mthumb -ffunction-sections -fdata-sections
			${CMAKE_SDK_ARM_ARCH_BUILD_FLOAT_OPTIONS}
			)

		set_target_properties(${CMAKE_SDK_SDK_TMP_TARGET}
			PROPERTIES NO_SYSTEM_FROM_IMPORTED TRUE
			)

		target_include_directories(${CMAKE_SDK_SDK_TMP_TARGET}
			PRIVATE
			${CMAKE_SDK_SDK_PATH}/arm-none-eabi/include/StratifyOS
			)

	else()
		target_include_directories(${CMAKE_SDK_SDK_TMP_TARGET}
			PRIVATE
			${CMAKE_SDK_SDK_PATH}/include/StratifyOS
			)

	endif()

	get_target_property(TARGET_BINARY_DIR ${CMAKE_SDK_SDK_TMP_TARGET} BINARY_DIR)

	install(
		TARGETS ${CMAKE_SDK_SDK_TMP_TARGET}
		EXPORT ${CMAKE_SDK_SDK_TMP_TARGET}
		DESTINATION lib
		OPTIONAL)
	install(
		EXPORT ${CMAKE_SDK_SDK_TMP_TARGET}
		DESTINATION ${CMAKE_SDK_SDK_PATH}/cmake/targets)

endfunction()
