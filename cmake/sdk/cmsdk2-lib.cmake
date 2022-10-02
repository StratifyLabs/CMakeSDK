function(cmsdk2_add_library)
	set(OPTIONS "")
	set(PREFIX ARGS)
	set(ONE_VALUE_ARGS TARGET NAME OPTION CONFIG ARCH TYPE)
	set(MULTI_VALUE_ARGS "")
	cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")
	set(REQUIRED_ARGS TARGET NAME CONFIG ARCH)
	foreach(VALUE ${REQUIRED_ARGS})
		if(NOT ARGS_${VALUE})
			message(FATAL_ERROR "cmsdk2_add_library requires ${VALUE}")
		endif()
	endforeach()
	if(ARGS_TYPE)
		set(LIBRARY_TYPE ${ARGS_TYPE})
	else()
		set(LIBRARY_TYPE STATIC)
	endif()
	cmsdk2_internal_build_target_name(
		NAME ${ARGS_NAME}
		OPTION ${ARGS_OPTION}
		CONFIG ${ARGS_CONFIG}
		ARCH ${ARGS_ARCH}
		RESULT TARGET_NAME
		BUILD_FOLDER TARGET_BUILD_FOLDER
	)
	add_library(${TARGET_NAME} ${LIBRARY_TYPE})
	if(ARGS_OPTION)
		set_target_properties(${TARGET_NAME} PROPERTIES
			CMSDK_PROPERTY_OPTION ${ARGS_OPTION})
	endif()
	set_target_properties(${TARGET_NAME} PROPERTIES
		CMSDK_PROPERTY_NAME ${ARGS_NAME}
		CMSDK_PROPERTY_CONFIG ${ARGS_CONFIG}
		CMSDK_PROPERTY_ARCH ${ARGS_ARCH}
		CMSDK_PROPERTY_BUILD_FOLDER ${TARGET_BUILD_FOLDER})
	target_compile_definitions(${TARGET_NAME}
		PRIVATE
		__${ARGS_ARCH}
		___${ARGS_CONFIG}
		CMSDK_BUILD_GIT_HASH=${CMSDK_GIT_HASH})
	if(OPTION)
		target_compile_definitions(${TARGET_NAME}
			PRIVATE
			__${OPTION})
	endif()
	if(${CMSDK_IS_ARM})
		cmsdk2_internal_get_arm_arch(
			ARCHITECTURE ${ARGS_ARCH}
			FLOAT_OPTIONS ARCH_BUILD_FLOAT_OPTIONS)
		target_compile_definitions(${TARGET_NAME}
			PUBLIC
			__StratifyOS__)
		target_compile_options(${TARGET_NAME}
			PRIVATE
			-mthumb -ffunction-sections -fdata-sections
			${ARCH_BUILD_FLOAT_OPTIONS})
		set_target_properties(${TARGET_NAME}
			PROPERTIES NO_SYSTEM_FROM_IMPORTED TRUE)
		target_include_directories(${TARGET_NAME}
			PRIVATE
			${CMSDK_LOCAL_PATH}/arm-none-eabi/include/StratifyOS)
	endif()
	get_target_property(TARGET_BINARY_DIR ${TARGET_NAME} BINARY_DIR)
	install(
		TARGETS ${TARGET_NAME}
		EXPORT ${TARGET_NAME}
		DESTINATION lib
		OPTIONAL)
	install(
		EXPORT ${TARGET_NAME}
		DESTINATION ${CMSDK_LOCAL_PATH}/cmake/targets)
	set(${ARGS_TARGET} ${TARGET_NAME} PARENT_SCOPE)
endfunction()

function(cmsdk2_library_add_dependencies)
	set(OPTIONS "")
	set(PREFIX ARGS)
	set(ONE_VALUE_ARGS TARGET)
	set(MULTI_VALUE_ARGS DEPENDENCIES TARGETS ARCHITECTURES)
	cmake_parse_arguments(PARSE_ARGV 0 ${PREFIX} "${OPTIONS}" "${ONE_VALUE_ARGS}" "${MULTI_VALUE_ARGS}")

	set(REQUIRED_ARGS TARGET)
	foreach(VALUE ${REQUIRED_ARGS})
		if(NOT ARGS_${VALUE})
			message(FATAL_ERROR "cmsdk2_update_target_for_architecture requires ${VALUE}")
		endif()
	endforeach()

	get_target_property(NAME ${ARGS_TARGET} CMSDK_PROPERTY_NAME)
	get_target_property(OPTION ${ARGS_TARGET} CMSDK_PROPERTY_OPTION)
	get_target_property(CONFIG ${ARGS_TARGET} CMSDK_PROPERTY_CONFIG)
	get_target_property(ARCH ${ARGS_TARGET} CMSDK_PROPERTY_ARCH)
	get_target_property(TARGET_BUILD_FOLDER ${ARGS_TARGET} CMSDK_PROPERTY_BUILD_FOLDER)

	if(${CMSDK_IS_LINK})

		if(ARGS_TARGETS)
			set(${ARGS_TARGETS} ${ARGS_TARGET} PARENT_SCOPE)
		endif()

		foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
			target_link_libraries(${ARGS_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${ARCH}
				)
			message(STATUS "${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
		endforeach()

	else()

		if(ARGS_TARGETS)
			set(${ARGS_TARGETS} ${ARGS_TARGET} PARENT_SCOPE)
		endif()

		foreach (ARCH ${ARGS_ARCHITECTURES})
			cmsdk_internal_is_arch_enabled(${ARCH})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmsdk2_add_library(
					TARGET TARGET_NAME
					NAME ${NAME}
					OPTION ${OPTION}
					CONFIG ${ARCH}
				)

				if(ARGS_TARGETS)
					list(APPEND ${ARGS_TARGETS} ${TARGET_NAME})
				endif()

				cmsdk2_copy_target(
					SOURCE ${ARGS_TARGET}
					DESTINATION ${TARGET_NAME}
				)

				foreach(DEPENDENCY ${DEPENDENCIES})
					target_link_libraries(${ARGS_TARGET}
						PUBLIC
						${DEPENDENCY}_${CONFIG}_${ARCH}
						)
					message(STATUS "${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
				endforeach()
			endif()
		endforeach(ARCH)

		foreach(DEPENDENCY ${DEPENDENCIES})
			target_link_libraries(${ARGS_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}
				)
			message(STATUS "${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
		endforeach()
	endif()

endfunction()

