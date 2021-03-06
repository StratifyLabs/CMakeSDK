include(${CMAKE_CURRENT_LIST_DIR}/sdk/sos-sdk-variables.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/sos-sdk-internal.cmake)

sos_sdk_internal_startup()

function(sos_sdk_pull PROJECT_PATH)
	execute_process(COMMAND ${SOS_SDK_GIT_EXEC} pull WORKING_DIRECTORY ${PROJECT_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
	message(STATUS "git pull " ${PROJECT_PATH} "\n" ${OUTPUT})
	if(RESULT)
		message(FATAL_ERROR " Failed to pull " ${PROJECT_PATH})
	endif()
endfunction()

function(sos_sdk_add_subdirectory INPUT_LIST DIRECTORY)
	add_subdirectory(${DIRECTORY})
	set(INPUT_SOURCES ${${INPUT_LIST}})
	set(TEMP_SOURCES "")
	foreach(entry ${SOURCES})
		list(APPEND TEMP_SOURCES ${DIRECTORY}/${entry})
	endforeach()
	list(APPEND TEMP_SOURCES ${INPUT_SOURCES})
	set(${INPUT_LIST} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()

function(sos_sdk_add_out_of_source_directory INPUT_LIST DIRECTORY BINARY_DIRECTORY)
	add_subdirectory(${DIRECTORY} ${BINARY_DIRECTORY})
	set(INPUT_SOURCES ${${INPUT_LIST}})
	set(TEMP_SOURCES "")
	foreach(entry ${SOURCES})
		list(APPEND TEMP_SOURCES ${DIRECTORY}/${entry})
	endforeach()
	list(APPEND TEMP_SOURCES ${INPUT_SOURCES})
	set(${INPUT_LIST} ${TEMP_SOURCES} PARENT_SCOPE)
endfunction()

function(sos_sdk_git_status PROJECT_PATH)
	message(STATUS "GIT STATUS OF " ${PROJECT_PATH})
	execute_process(COMMAND ${SOS_SDK_GIT_EXEC} status WORKING_DIRECTORY ${PROJECT_PATH} RESULT_VARIABLE RESULT)
endfunction()

function(sos_sdk_clone REPO_URL WORKSPACE_PATH)
	execute_process(COMMAND ${SOS_SDK_GIT_EXEC} clone ${REPO_URL} WORKING_DIRECTORY ${WORKSPACE_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
	message(STATUS "git clone " ${REPO_URL} to ${WORKSPACE_PATH} "\n" ${OUTPUT})
	if(RESULT)
		message(FATAL_ERROR " Failed to clone " ${PROJECT_PATH})
	endif()
endfunction()

function(sos_sdk_clone_or_pull PROJECT_PATH REPO_URL WORKSPACE_PATH)
	#if ${PROJECT_PATH} directory doesn't exist -- clone from the URL
	if(EXISTS ${PROJECT_PATH}/.git)
		message(STATUS ${PROJECT_PATH} " already exists: pulling")
		sos_sdk_pull(${PROJECT_PATH})
	else()
		file(REMOVE_RECURSE ${PROJECT_PATH})
		message(STATUS ${PROJECT_PATH} " does not exist: cloning")
		sos_sdk_clone(${REPO_URL} ${WORKSPACE_PATH})
	endif()
endfunction()

function(sos_sdk_checkout PROJECT_PATH GIT_PATH)
	execute_process(COMMAND ${SOS_SDK_GIT_EXEC} checkout ${GIT_PATH} WORKING_DIRECTORY ${PROJECT_PATH} OUTPUT_VARIABLE OUTPUT RESULT_VARIABLE RESULT)
	message(STATUS "git checkout " ${GIT_PATH} " in " ${PROJECT_PATH} "\n" ${OUTPUT})
	if(RESULT)
		message(FATAL_ERROR " Failed to checkout " ${PROJECT_PATH} ${GIT_PATH})
	endif()
endfunction()

function(sos_sdk_copy_target SOURCE_TARGET DEST_TARGET)
	sos_sdk_internal_shared_properties()
	foreach (PROPERTY ${SOS_SHARED_PROPERTIES})
		string(REPLACE "<CONFIG>" "${CMAKE_BUILD_TYPE}" prop ${PROPERTY})
		get_property(PROPERTY_VALUE TARGET ${SOURCE_TARGET} PROPERTY ${PROPERTY} SET)

		if (PROPERTY_VALUE)
			get_target_property(PROPERTY_VALUE ${SOURCE_TARGET} ${PROPERTY})
			set_property(TARGET ${DEST_TARGET} PROPERTY ${PROPERTY} ${PROPERTY_VALUE})
		endif()

	endforeach(PROPERTY)
endfunction()

function(sos_sdk_add_test NAME OPTION CONFIG)

	string(COMPARE EQUAL ${OPTION} "" OPTION_IS_EMPTY)

	if(OPTION_IS_EMPTY)
		set(EXEC_NAME ${NAME})
		set(DIR_NAME build)
	else()
		set(EXEC_NAME ${NAME}_${OPTION})
		set(DIR_NAME build_${OPTION})
	endif()

	set(EXEC_NAME ${EXEC_NAME}_${CONFIG})
	set(TARGET_NAME ${EXEC_NAME}_link.elf)

	get_target_property(TARGET_BINARY_DIR ${TARGET_NAME} RUNTIME_OUTPUT_DIRECTORY)

	message(STATUS "SOS SDK - Add test ${TARGET_BINARY_DIR}/${TARGET_NAME}")

	add_test(NAME ${NAME}_${CONFIG}
		COMMAND "${TARGET_BINARY_DIR}/${TARGET_NAME}" --api
		)

	set_tests_properties(
		${NAME}_${CONFIG}
		PROPERTIES
		PASS_REGULAR_EXPRESSION "___finalResultPass___"
		)

endfunction()

function(sos_sdk_exclude_arch_from_all TARGET ARCH_LIST)
	foreach(ARCH ${ARCH_LIST})
		set_target_properties(${TARGET}_${ARCH}
			PROPERTIES EXCLUDE_FROM_ALL ON
			)
	endforeach()
endfunction()

macro(sos_sdk_include_target TARGET CONFIG_LIST)
	if(SOS_IS_ARM)
		set(ARCH_LIST ${SOS_ARCH} ${SOS_ARCH_LIST})
	else()
		set(ARCH_LIST link)
	endif()

	foreach(CONFIG ${CONFIG_LIST})
		foreach(ARCH ${ARCH_LIST})
			include(${TARGET}_${CONFIG}_${ARCH})
		endforeach(ARCH)
	endforeach(CONFIG)

endmacro()


include(${CMAKE_CURRENT_LIST_DIR}/sdk/sos-sdk-app.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/sos-sdk-bsp.cmake)
include(${CMAKE_CURRENT_LIST_DIR}/sdk/sos-sdk-lib.cmake)




