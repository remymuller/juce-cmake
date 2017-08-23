#.rst:	
# FindJUCE
# ---------	
#	
# Find JUCE library 
# 
# Use this module by invoking find_package with the form::
# 
#   find_package(JUCE
#     [REQUIRED]             # Fail with error if JUCE is not found
#     [COMPONENTS <libs>...] # JUCE modules by their canonical name
#     )                      # e.g. "juce_core"
# 
# This module finds headers and requested component libraries. 
# Results are reported in variables::
# 
#   JUCE_FOUND              - True if headers and requested modules were found
#   JUCE_INCLUDE_DIR        - JUCE include directories
#	JUCE_PATH				- path to JUCE 
#   JUCE_LIBRARIES          - JUCE component libraries to be linked
#	JUCE_SOURCES			- JUCE library sources
#   JUCE_<C>_FOUND          - True if component <C> was found 
#   JUCE_<C>_HEADER         - Module header for component <C> 
#   JUCE_<C>_SOURCES        - Module sources for component <C> 
#   JUCE_<C>_LIBRARY        - Libraries to link for component <C>
#   JUCE_VERSION            - JUCE_VERSION value from boost/version.hpp
#   JUCE_MAJOR_VERSION      - JUCE major version number (X in X.y.z)
#   JUCE_MINOR_VERSION      - JUCE minor version number (Y in x.Y.z)
#   JUCE_SUBMINOR_VERSION   - JUCE subminor version number (Z in x.y.Z)


#------------------------------------------------------------------------------
# helpers
#------------------------------------------------------------------------------

function(juce_module_declaration_set_properties prefix module_declaration properties)
	# 
	# 

	foreach(property ${properties})
		set(${prefix}_${property} "" PARENT_SCOPE)

		set(pattern "^.*${property}: *(.*)$")

		foreach(line ${module_declaration})
			if(line MATCHES ${pattern})
				string(REGEX REPLACE ${pattern} "\\1" var_raw "${line}")
				string(REGEX REPLACE " |," ";" var_clean "${var_raw}")

				# debug 
				# message("line: ${line}")
				# message("var_raw: ${var_raw}")
				# message("var_clean: ${var_clean}")

				set(${prefix}_${property} ${var_clean} PARENT_SCOPE)
			endif()
		endforeach() 
	endforeach() 
endfunction()


function(juce_module_get_declaration module_info module_header)
	file(READ ${module_header} text)

	# Extract block
	set(pattern ".*(BEGIN_JUCE_MODULE_DECLARATION)(.+)(END_JUCE_MODULE_DECLARATION).*")
	string(REGEX REPLACE ${pattern} "\\2" module_declaration ${text})
	#message("${module_declaration}")

	# split block into lines
	string(REGEX REPLACE "\r?\n" ";" module_declaration_lines ${module_declaration})

	set(${module_info} ${module_declaration_lines} PARENT_SCOPE)
endfunction()


function(juce_module_get_info module_header)
	# get parsed module declaration as lines
	juce_module_get_declaration(JUCE_${module}_declaration ${JUCE_${module}_HEADER})

	# get properties	
	set(properties 
		dependencies 
		OSXFrameworks 
		OSXLibs
		iOSFrameworks 
		iOSLibs
		linuxLibs
		windowsLibs
		minimumCppStandard
		searchpaths
	)
	set(prefix JUCE_${module})
	juce_module_declaration_set_properties(${prefix} "${JUCE_${module}_declaration}" "${properties}")

	# forward properties to parent scope
	foreach(property ${properties})
		set(JUCE_${module}_${property} ${JUCE_${module}_${property}} PARENT_SCOPE)
	endforeach()
endfunction()


macro(juce_module_set_platformlibs module)
	set(JUCE_${module}_platformlibs "")

	if(APPLE_IOS OR IOS OR ${CMAKE_SYSTEM_NAME} MATCHES iOS)
		set(_libs ${JUCE_${module}_iOSFrameworks} ${JUCE_${module}_iOSLibs})
	elseif(APPLE)
		set(_libs ${JUCE_${module}_OSXFrameworks} ${JUCE_${module}_OSXLibs})
	elseif(WINDOWS)
		set(_libs ${JUCE_${module}_windowsLibs})
	#elseif(Android)
	elseif(Linux)
		set(_libs ${JUCE_${module}_linuxLibs})
	else()
	endif()

	foreach(_lib ${_libs})
		find_library(JUCE_LIB_${_lib} ${_lib})
		list(APPEND JUCE_${module}_platformlibs ${JUCE_LIB_${_lib}})
	endforeach()

	unset(_lib)
	unset(_libs)

endmacro()

#------------------------------------------------------------------------------

macro(juce_add_module module)
	if(TARGET ${module})
		# debug
		# message("juce_add_module: NO \t${module}")
	else()
		# debug
		# message("juce_add_module: YES\t${module}")

		set(JUCE_${module}_HEADER "${JUCE_MODULES_PREFIX}/${module}/${module}.h")

		juce_module_get_info(JUCE_${module}_INFO ${JUCE_${module}_HEADER})
		juce_module_set_platformlibs(${module})

		# debug
		# set(properties 
		# 	dependencies 
		# 	OSXFrameworks 
		# 	iOSFrameworks 
		# 	linuxLibs
		# )
		# foreach(property ${properties})
		# 	message("JUCE_${module}_${property}:\t${JUCE_${module}_${property}}")
		# endforeach()

		# generate sources wrappers
		set(JUCE_${module}_SOURCES "")
		file(GLOB JUCE_${module}_CPP_FILES 
			LIST_DIRECTORIES false
			"${JUCE_MODULES_PREFIX}/${module}/${module}*.cpp")

		foreach(cpp_file ${JUCE_${module}_CPP_FILES})
			get_filename_component(module_source_basename ${cpp_file} NAME_WE)
			#message("\t${module_source_basename}")

			if(APPLE)
				set(_ext "mm")
			else()
				set(_ext "cpp")
			endif()

		    set(JUCE_${module}_current_source "${PROJECT_BINARY_DIR}/JuceLibraryCode/include_${module_source_basename}.${_ext}")
		    set(JUCE_CURRENT_MODULE ${module})
			configure_file(
				"${CMAKE_CURRENT_LIST_DIR}/templates/include_juce_module.cpp.in" 				
				"${JUCE_${module}_current_source}"
			)
			list(APPEND JUCE_${module}_SOURCES "${JUCE_${module}_current_source}")

			unset(_ext)
			unset(module_source_basename)
		endforeach()

		# generate INTERFACE library for module
		add_library(${module} INTERFACE)
		target_include_directories(${module} INTERFACE ${JUCE_${module}_searchpaths})
		target_sources(${module} INTERFACE ${JUCE_${module}_SOURCES})
    	target_link_libraries(${module} INTERFACE juce_common)
	    target_link_libraries(${module} INTERFACE "${JUCE_${module}_dependencies}")
	    #message("${JUCE_${module}_platformlibs}")
	    target_link_libraries(${module} INTERFACE "${JUCE_${module}_platformlibs}")

    	# set global variables
		set(JUCE_${module}_FOUND true)
		list(APPEND JUCE_LIBRARIES ${module})
		list(APPEND JUCE_SOURCES ${JUCE_${module}_SOURCES})

		# tail recursion into dependent modules
		foreach(dependent_module ${JUCE_${module}_dependencies}) 
			juce_add_module(${dependent_module})
		endforeach()
	endif()
endmacro()

#------------------------------------------------------------------------------

# First find JUCE
find_path(JUCE_PATH 
	"modules/JUCE Module Format.txt"
	HINTS
		${PROJECT_SOURCE_DIR}/../
		${PROJECT_SOURCE_DIR}/JUCE
		${CMAKE_CURRENT_LIST_DIR}/../../JUCE
		${CMAKE_CURRENT_LIST_DIR}/../JUCE
	DOC 
		"JUCE library directory"
)
set(JUCE_MODULES_PREFIX "${JUCE_PATH}/modules")
set(JUCE_INCLUDE_DIR ${JUCE_MODULES_PREFIX})
set(JUCE_INCLUDES ${JUCE_INCLUDE_DIR} "${PROJECT_BINARY_DIR}/JuceLibraryCode")

#------------------------------------------------------------------------------

# then define common target
add_library(juce_common INTERFACE)
target_include_directories(juce_common INTERFACE ${JUCE_INCLUDES})
target_compile_features(juce_common INTERFACE cxx_auto_type cxx_constexpr)
# set_target_properties(juce_common PROPERTIES
#    INTERFACE_COMPILE_DEFINITIONS         NDEBUG
    # INTERFACE_COMPILE_DEFINITIONS_DEBUG   DEBUG
#    INTERFACE_COMPILE_DEFINITIONS_RELEASE NDEBUG
# )

set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -DDEBUG")

#------------------------------------------------------------------------------

# then find components
set(JUCE_LIBRARIES "")
set(JUCE_SOURCES "")
foreach(module ${JUCE_FIND_COMPONENTS})
	juce_add_module(${module})
endforeach()

#------------------------------------------------------------------------------
# now generate AppConfig.h

# generate module defineoptions
set(JUCE_MODULE_AVAILABLE_DEFINE_LIST "")
foreach(module ${JUCE_LIBRARIES})
	if(JUCE__AVAILABLE_${module})
		string(APPEND JUCE_MODULE_AVAILABLE_DEFINE_LIST "#define JUCE_MODULE_AVAILABLE_${module}\t1\n")
	else()
		string(APPEND JUCE_MODULE_AVAILABLE_DEFINE_LIST "#define JUCE_MODULE_AVAILABLE_${module}\t0\n")
	endif()
endforeach()
unset(JUCE_MODULE_AVAILABLE_DEFINE_LIST)

set(JUCE_APPCONFIG_H "${PROJECT_BINARY_DIR}/JuceLibraryCode/AppConfig.h")
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/AppConfig.h.in" ${JUCE_APPCONFIG_H})
list(APPEND JUCE_INCLUDES "${PROJECT_BINARY_DIR}/JuceLibraryCode")


# and generate JuceHeader.h
set(JUCE_MODULE_INCLUDES_LIST "")
foreach(module ${JUCE_LIBRARIES})
    if(TARGET ${module})
        string(APPEND JUCE_MODULE_INCLUDES_LIST "#include <${module}/${module}.h>\n")
    endif()
endforeach()

set(JUCE_HEADER_H "${PROJECT_BINARY_DIR}/JuceLibraryCode/JuceHeader.h")
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/JuceHeader.h.in" ${JUCE_HEADER_H})
unset(JUCE_MODULE_INCLUDES_LIST)

#------------------------------------------------------------------------------

# update common sources
target_sources(juce_common INTERFACE ${JUCE_APPCONFIG_H} ${JUCE_HEADER_H})
list(APPEND JUCE_SOURCES ${JUCE_APPCONFIG_H} ${JUCE_HEADER_H})


#------------------------------------------------------------------------------
# for each library 
# handle dependencies

#------------------------------------------------------------------------------
# organize sources in IDE
source_group(JuceLibraryCode FILES ${JUCE_SOURCES})

#------------------------------------------------------------------------------

# finalize
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(JUCE DEFAULT_MSG 
	JUCE_INCLUDE_DIR 
	JUCE_LIBRARIES 
	JUCE_SOURCES
)
