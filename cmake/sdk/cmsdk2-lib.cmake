function(cmsdk2_add_library)
	cmsdk2_internal_parse_arguments(
		INTERNAL_FUNCTION_NAME cmsdk2_add_library
		ARGUMENTS ${ARGV}
		REQUIRED TARGET NAME CONFIG ARCH
		ONE_VALUE TARGET NAME OPTION CONFIG ARCH TYPE TARGETS)

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
	message(STATUS "CMSDK2 Add Library ${ARGS_NAME} option:${ARGS_OPTION} config:${ARGS_CONFIG} arch:${ARGS_ARCH}")

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
	if(OPTION AND NOT TYPE STREQUAL INTERFACE)
		target_compile_definitions(${TARGET_NAME}
			PRIVATE
			__${OPTION})
	endif()
	if(${CMSDK_IS_ARM})
		set_target_properties(${TARGET_NAME}
			PROPERTIES NO_SYSTEM_FROM_IMPORTED TRUE)
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
	cmsdk2_internal_parse_arguments(
		INTERNAL_FUNCTION_NAME cmsdk2_library_add_dependencies
		ARGUMENTS ${ARGV}
		REQUIRED TARGET
		ONE_VALUE TARGET
		MULTI_VALUE DEPENDENCIES TARGETS ARCHITECTURES)

	cmsdk2_internal_get_target_components(${ARGS_TARGET})

	message(STATUS "CMSDK2 Add Library Dependencies ${NAME} option:${OPTION} config:${CONFIG} arch:${ARCH}")

	if(CMSDK_IS_LINK)
		if(ARGS_TARGETS)
			set(${ARGS_TARGETS} ${ARGS_TARGET} PARENT_SCOPE)
		endif()
		foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
			target_link_libraries(${ARGS_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${ARCH})
			message(STATUS "  ${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${CMSDK_ARCH}")
		endforeach()
	else()
		if(ARGS_TARGETS)
			set(${ARGS_TARGETS} ${ARGS_TARGET} PARENT_SCOPE)
		endif()
		foreach(ARCH_FROM_LIST ${ARGS_ARCHITECTURES})
			cmsdk_internal_is_arch_enabled(${ARCH_FROM_LIST})
			if(ARCH_ENABLED)
				set(TARGET_NAME ${BASE_NAME})
				if(NOT OPTION STREQUAL "")
					set(TARGET_NAME ${TARGET_NAME}_${OPTION})
				endif()

				cmsdk2_add_library(
					TARGET TARGET_NAME
					NAME ${NAME}
					ARCH ${ARCH_FROM_LIST}
					OPTION ${OPTION}
					CONFIG ${CONFIG})
				if(ARGS_TARGETS)
					list(APPEND ${ARGS_TARGETS} ${TARGET_NAME})
				endif()
				cmsdk2_copy_target(
					SOURCE ${ARGS_TARGET}
					DESTINATION ${TARGET_NAME})
				foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
					target_link_libraries(${TARGET_NAME}
						PUBLIC
						${DEPENDENCY}_${CONFIG}_${ARCH})
					message(STATUS "  ${TARGET_NAME} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
				endforeach()
			endif()
		endforeach()

		foreach(DEPENDENCY ${ARGS_DEPENDENCIES})
			target_link_libraries(${ARGS_TARGET}
				PUBLIC
				${DEPENDENCY}_${CONFIG}_${ARCH})
			message(STATUS "  ${ARGS_TARGET} -> ${DEPENDENCY}_${CONFIG}_${ARCH}")
		endforeach()
	endif()

endfunction()

