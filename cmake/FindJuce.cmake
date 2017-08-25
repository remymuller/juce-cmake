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
#	JUCE_ROOT_DIR			- path to JUCE 
#   JUCE_LIBRARIES          - JUCE component libraries to be linked
#   JUCE_MODULES            - list of resolved modules
#	JUCE_SOURCES			- JUCE library sources
#   JUCE_<C>_FOUND          - True if component <C> was found 
#   JUCE_<C>_HEADER         - Module header for component <C> 
#   JUCE_<C>_SOURCES        - Module sources for component <C>  
#   JUCE_<C>_LIBRARY        - Libraries to link for component <C>
#   JUCE_CONFIG_<C>         - Juce Config for variable <C>
#?   JUCE_VERSION           - JUCE_VERSION value from boost/version.hpp
#?   JUCE_VERSION_MAJOR     - JUCE major version number (X in X.y.z)
#?   JUCE_VERSION_MINOR     - JUCE minor version number (Y in x.Y.z)
#?   JUCE_VERSION_SUBMINOR  - JUCE subminor version number (Z in x.y.Z)
# 
#   Multiple Calls to find_package
#   ------------------------------
#   
#   for multiple calls to find_package(JUCE) with different COMPONENTS, 
#   module variables and targets are cached on the first time they are found, 
#   but a unique 'merge' target with sources to be built and only the requested 
#   components is created each time.
# 
#   Config Flags can be set globally for all calls to find_package(JUCE) using the 
#   cache variables JUCE_CONFIG_<flag>, but they can be overriden locally by 
#   using target_compile_definitions(target "JUCE_<flag>=1")


#------------------------------------------------------------------------------
# helpers
#------------------------------------------------------------------------------

function(juce_module_declaration_set_properties prefix module_declaration properties)
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

#------------------------------------------------------------------------------

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

#------------------------------------------------------------------------------

function(juce_module_get_info module)
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
        #message("JUCE_${module}_${property}:\t${JUCE_${module}_${property}}")
	endforeach()

    set(JUCE_${module}_minimumCppStandard ${JUCE_${module}_minimumCppStandard} CACHE STRING "")
endfunction()

#------------------------------------------------------------------------------

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
        mark_as_advanced(JUCE_LIB_${_lib})
		list(APPEND JUCE_${module}_platformlibs ${JUCE_LIB_${_lib}})
	endforeach()

    # set(JUCE_${module}_platformlibs ${JUCE_${module}_platformlibs} CACHE STRING "")

	unset(_lib)
	unset(_libs)
endmacro()

#------------------------------------------------------------------------------

function(juce_module_get_config_flags module)
    # 
    # Parses the module header for Config flags patterns.
    # 
    # Example:
    #   /** Config: JUCE_ALSA
    #       Enables ALSA audio devices (Linux only).
    #   */
    #   #ifndef JUCE_ALSA
    #   #define JUCE_ALSA 1
    #   #endif

    set(pattern "/\\*\\* *Config: *(JUCE_[_a-zA-Z]+)[ \n]")

    set(header ${JUCE_${module}_HEADER})
    file(READ ${header} text)

    set(flags "")
    string(REGEX MATCHALL ${pattern} matches ${text})
    foreach(match ${matches})
        string(REGEX REPLACE ${pattern} "\\1" flag ${match})
        list(APPEND flags ${flag})
    endforeach()

    set(JUCE_${module}_CONFIG_FLAGS ${flags} CACHE STRING "Config flags for JUCE module ${module}")
    mark_as_advanced(JUCE_${module}_CONFIG_FLAGS)

    foreach(flag ${flags})
        set(JUCE_CONFIG_${flag} default CACHE STRING "") # TODO extract doc from header
        mark_as_advanced(JUCE_CONFIG_${flag})

        set_property(
            CACHE JUCE_CONFIG_${flag} 
            PROPERTY STRINGS "default;ON;OFF"
        )
    endforeach()

endfunction()

#------------------------------------------------------------------------------

function(juce_gen_config_flags_str var)
    set(str "")

    foreach(module ${JUCE_MODULES})
        if(TARGET ${module})
            string(LENGTH "${JUCE_${module}_CONFIG_FLAGS}" len)
            if(NOT ${len})
                continue()
            endif()

            string(APPEND str            
                "//==============================================================================\n"
                "// ${module} flags:\n"
                "\n"
            )

            foreach(_flag ${JUCE_${module}_CONFIG_FLAGS})
                string(APPEND str            
                    "#ifndef    ${_flag}\n"
                )

                #message("${JUCE_CONFIG_${_flag}}")

                unset(value)
                if(DEFINED ${_flag})    # has higher precedence over cache
                    if(${_flag})
                        set(value 1)
                    else()
                        set(value 0)
                    endif()
                else()                  # check cache
                    if(${JUCE_CONFIG_${_flag}} MATCHES ON)
                        set(value 1)
                    elseif(${JUCE_CONFIG_${_flag}} MATCHES OFF)
                        set(value 0)
                    endif()
                endif()

                if(DEFINED ${value})
                    string(APPEND str "  #define ${_flag} ${value}\n")
                else()
                    string(APPEND str "  // #define ${_flag}\n")
                endif()

                # debug
                #message("Config Flag: ${_flag}=${value}")

                string(APPEND str
                    "#endif\n"
                    "\n"
                )
            endforeach()
        endif()
    endforeach()    

    set(${var} ${str} PARENT_SCOPE)
endfunction()

#------------------------------------------------------------------------------

function(juce_generate_app_config output_file)
    # generate module defineoptions
    juce_gen_config_flags_str(JUCE_CONFIG_FLAGS)
    set(JUCE_MODULES_AVAILABLE "")

    foreach(module ${JUCE_MODULES})
        if(TARGET ${module})
            string(APPEND JUCE_MODULES_AVAILABLE 
                "#define JUCE_MODULE_AVAILABLE_${module}\t1\n"
            )
        else()
            string(APPEND JUCE_MODULES_AVAILABLE 
                "#define JUCE_MODULE_AVAILABLE_${module}\t0\n"
            )
        endif()
    endforeach()

    configure_file("${CMAKE_CURRENT_LIST_DIR}/FindJuceTemplates/AppConfig.h.in" ${output_file})
endfunction()

#------------------------------------------------------------------------------

function(juce_generate_juce_header output_file)
    if(DEFINED JUCE_PROJECT_NAME)
        set(JuceProjectName ${JUCE_PROJECT_NAME})
    else()
        set(JuceProjectName ${PROJECT_NAME})
    endif()

    set(JUCE_MODULE_INCLUDES "")
    foreach(module ${JUCE_MODULES})
        if(TARGET ${module})
            string(APPEND JUCE_MODULE_INCLUDES "#include <${module}/${module}.h>\n")
        endif()
    endforeach()

    configure_file("${CMAKE_CURRENT_LIST_DIR}/FindJuceTemplates/JuceHeader.h.in" ${output_file})
endfunction()

#------------------------------------------------------------------------------

macro(juce_add_module module)
    if(${JUCE_${module}_FOUND})
		# debug
		#message("juce_add_module: NO \t${module}")
	else()
		# debug
		#message("juce_add_module: YES\t${module}")

		set(JUCE_${module}_HEADER "${JUCE_MODULES_PREFIX}/${module}/${module}.h" CACHE PATH "Header for JUCE module ${module}")
        mark_as_advanced(JUCE_${module}_HEADER)

		juce_module_get_info(${module})

		juce_module_set_platformlibs(${module})
        juce_module_get_config_flags(${module})


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

		# generate immutable INTERFACE IMPORTED library for module
        if(NOT TARGET ${module})
    		add_library(${module} INTERFACE IMPORTED)
            set_property(TARGET ${module} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${JUCE_${module}_searchpaths})
            set_property(TARGET ${module} PROPERTY INTERFACE_LINK_LIBRARIES 
                    juce_common
                    "${JUCE_${module}_dependencies}"
                    "${JUCE_${module}_platformlibs}"
            )

            # set_property(TARGET ${module} PROPERTY INTERFACE_COMPILE_OPTIONS)
            # set_property(TARGET ${module} PROPERTY INTERFACE_COMPILE_DEFINITIONS)
        else()
            #message("target: ${module} already defined")
        endif()

    	# set global variables
        set(JUCE_${module}_FOUND true)

        list(APPEND JUCE_MODULES ${module})

		# tail recursion into dependent modules
		foreach(dependent_module ${JUCE_${module}_dependencies}) 
			juce_add_module(${dependent_module})
		endforeach()
	endif()
endmacro()

#------------------------------------------------------------------------------
# First find JUCE
find_path(JUCE_ROOT_DIR 
	"modules/JUCE Module Format.txt"
	HINTS
		${PROJECT_SOURCE_DIR}/../
		${PROJECT_SOURCE_DIR}/JUCE
		${CMAKE_CURRENT_LIST_DIR}/../../JUCE
		${CMAKE_CURRENT_LIST_DIR}/../JUCE
	DOC 
		"JUCE library directory"
)
set(JUCE_MODULES_PREFIX "${JUCE_ROOT_DIR}/modules")
mark_as_advanced(JUCE_ROOT_DIR)

set(JUCE_INCLUDE_DIR ${JUCE_MODULES_PREFIX} CACHE PATH "Juce modules include directory")
mark_as_advanced(JUCE_INCLUDE_DIR)

set(JUCE_INCLUDES ${JUCE_INCLUDE_DIR} "${PROJECT_BINARY_DIR}/JuceLibraryCode")

#------------------------------------------------------------------------------
# get VERSION
set(_version_pattern "[ \t]*version:[ \t]*(([0-9]+).([0-9]+).([0-9]+))")
file(STRINGS "${JUCE_MODULES_PREFIX}/juce_core/juce_core.h" JUCE_VERSIONS REGEX ${_version_pattern})
string(REGEX REPLACE "${_version_pattern}" "\\1" JUCE_VERSION ${JUCE_VERSIONS})
string(REGEX REPLACE "${_version_pattern}" "\\2" JUCE_VERSION_MAJOR ${JUCE_VERSIONS})
string(REGEX REPLACE "${_version_pattern}" "\\3" JUCE_VERSION_MINOR ${JUCE_VERSIONS})
string(REGEX REPLACE "${_version_pattern}" "\\4" JUCE_VERSION_SUBMINOR ${JUCE_VERSIONS})

foreach(_var JUCE_VERSION JUCE_VERSION_MAJOR JUCE_VERSION_MINOR JUCE_VERSION_SUBMINOR)
    set(${_var} ${${_var}} CACHE STRING "")
    mark_as_advanced(${_var})
endforeach()

#------------------------------------------------------------------------------
# Global options

option(JUCE_DISPLAY_SPLASH_SCREEN "" OFF)
option(JUCE_REPORT_APP_USAGE "" OFF)
option(JUCE_USE_DARK_SPLASH_SCREEN "" ON)

#------------------------------------------------------------------------------
# then define common target

if(NOT TARGET juce_common)
    add_library(juce_common INTERFACE)
    target_include_directories(juce_common INTERFACE ${JUCE_INCLUDE_DIR})
    target_compile_features(juce_common INTERFACE cxx_auto_type cxx_constexpr) # TODO make this per module
    target_compile_options(juce_common INTERFACE $<$<CONFIG:Debug>:-DDEBUG>) # avoid warning in juce code
endif()

#------------------------------------------------------------------------------
# then find components

set(JUCE_MODULES "")
foreach(module ${JUCE_FIND_COMPONENTS})
	juce_add_module(${module})
endforeach()

#------------------------------------------------------------------------------
# now generate specific target for this call to find_package

# TODO: we could make it unique for each call to find_package if necessary using String(RANDOM) to suffix it
set(JuceLibraryCode "${PROJECT_BINARY_DIR}/JuceLibraryCode")
list(APPEND JUCE_INCLUDES "${JuceLibraryCode}")

# generate AppConfig.h
set(JUCE_APPCONFIG_H "${JuceLibraryCode}/AppConfig.h")
juce_generate_app_config(${JUCE_APPCONFIG_H})

# generate JuceHeader.h
set(JUCE_HEADER_H "${JuceLibraryCode}/JuceHeader.h")
juce_generate_juce_header(${JUCE_HEADER_H})

set(JUCE_SOURCES 
    ${JUCE_APPCONFIG_H} 
    ${JUCE_HEADER_H}
)

# generate JuceLibraryCode Wrappers
foreach(module ${JUCE_MODULES})
    # generate sources wrappers
    set(JUCE_${module}_SOURCES "")
    file(GLOB JUCE_${module}_CPP_FILES 
        LIST_DIRECTORIES false
        "${JUCE_MODULES_PREFIX}/${module}/${module}*.cpp")

    foreach(cpp_file ${JUCE_${module}_CPP_FILES})
        get_filename_component(module_source_basename ${cpp_file} NAME_WE)

        if(APPLE)
            set(_ext "mm")
        else()
            set(_ext "cpp")
        endif()

        set(JUCE_${module}_current_source "${JuceLibraryCode}/include_${module_source_basename}.${_ext}")
        set(JUCE_CURRENT_MODULE ${module})
        configure_file(
            "${CMAKE_CURRENT_LIST_DIR}/FindJuceTemplates/include_juce_module.cpp.in"                
            "${JUCE_${module}_current_source}"
        )
        list(APPEND JUCE_${module}_SOURCES "${JUCE_${module}_current_source}")
        list(APPEND JUCE_SOURCES "${JUCE_${module}_current_source}")

        unset(_ext)
        unset(module_source_basename)
    endforeach()
endforeach()

# look for required CXX standard
set(JUCE_CXX_STANDARD 11)
foreach(module ${JUCE_MODULES})
    # check for required C++ version
    if("${JUCE_${module}_minimumCppStandard}" GREATER ${JUCE_CXX_STANDARD})
        set(JUCE_CXX_STANDARD ${JUCE_${module}_minimumCppStandard})
    endif()
endforeach()
message("using CXX: ${JUCE_CXX_STANDARD}")

# create unique merge target per binary directory
string(MD5 juce_target_md5 "${PROJECT_BINARY_DIR}")
set(JUCE_TARGET juce-${juce_target_md5})

add_library(${JUCE_TARGET} INTERFACE)
target_include_directories(${JUCE_TARGET} INTERFACE ${JuceLibraryCode})
target_link_libraries(${JUCE_TARGET} INTERFACE juce_common ${JUCE_MODULES})
target_sources(${JUCE_TARGET} INTERFACE ${JUCE_SOURCES})

# set CXX standard
target_compile_features(${JUCE_TARGET} INTERFACE cxx_std_${JUCE_CXX_STANDARD})

# export this target to be linked by client code
set(JUCE_LIBRARIES ${JUCE_TARGET})


#------------------------------------------------------------------------------
# organize sources in IDE
source_group(JuceLibraryCode FILES ${JUCE_SOURCES})


#------------------------------------------------------------------------------
# finalize
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(JUCE DEFAULT_MSG 
    JUCE_ROOT_DIR
	JUCE_INCLUDE_DIR 
)
