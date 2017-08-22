###############################################################################
# 
#   Juce Modules
# 
###############################################################################


# TODO: add juce_common pseudo target to configure AppConfig.h file and define common includes


###############################################################################
# find list of all modules

get_filename_component(JUCE_PREFIX "../JUCE" ABSOLUTE BASE_DIR ${PROJECT_SOURCE_DIR})
set(JUCE_MODULES_PREFIX "${JUCE_PREFIX}/modules")
set(JUCE_INCLUDES ${JUCE_MODULES_PREFIX})

set(modules "")
file(GLOB children RELATIVE ${JUCE_MODULES_PREFIX} ${JUCE_MODULES_PREFIX}/juce_*)
foreach(child ${children})
	if(IS_DIRECTORY ${JUCE_MODULES_PREFIX}/${child})
		message("found module: ${child}")
		list(APPEND modules ${child})
	endif()
endforeach()


###############################################################################
# helpers 

# function(juce_get_module_info module_info module_header)
# 	file(READ ${module_header} juce_module_header_str)

# 	# Extract block
# 	set(juce_module_info_pattern ".*(BEGIN_JUCE_MODULE_DECLARATION)(.+)(END_JUCE_MODULE_DECLARATION).*")
# 	string(REGEX REPLACE ${juce_module_info_pattern} "\\2" juce_module_info ${juce_module_header_str})

# 	# split block into lines
# 	string(REGEX REPLACE "\r?\n" ";" lines ${juce_module_info})

# 	set(${module_info} ${lines} PARENT_SCOPE)
# endfunction()

function(juce_module_get_array_property var property module_header)
	file(READ ${module_header} juce_module_header_str)

	# Extract block
	set(juce_module_info_pattern ".*(BEGIN_JUCE_MODULE_DECLARATION)(.+)(END_JUCE_MODULE_DECLARATION).*")
	string(REGEX REPLACE ${juce_module_info_pattern} "\\2" juce_module_info ${juce_module_header_str})

	# split block into lines
	string(REGEX REPLACE "\r?\n" ";" lines ${juce_module_info})

	set(pattern "^.*${property}: *(.*)$")
	set(${property} "" PARENT_SCOPE)

	foreach(line ${lines})
		if(line MATCHES ${pattern})
			string(REGEX REPLACE ${pattern} "\\1" var_raw "${line}")
			string(REGEX REPLACE " |," ";" var_clean "${var_raw}")
			set(${var} ${var_clean} PARENT_SCOPE)
		endif()
	endforeach() 
endfunction()


###############################################################################
# generate module options
foreach(module ${modules})
	option(JUCE_MODULE_AVAILABLE_${module} "Enable JUCE module ${module}" ON)
endforeach()


###############################################################################
# generate JuceHeader.h
set(JUCE_MODULE_INCLUDES_LIST "")
foreach(module ${modules})
    if(JUCE_MODULE_AVAILABLE_${module})
        string(APPEND JUCE_MODULE_INCLUDES_LIST "#include <${module}/${module}.h>\n")
    endif()
endforeach()

set(JUCE_HEADER_H "${PROJECT_BINARY_DIR}/JuceLibraryCode/JuceHeader.h")
configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/JuceHeader.h.in" ${JUCE_HEADER_H})


###############################################################################
# generate AppConfig.h

# generate module defineoptions
set(JUCE_MODULE_AVAILABLE_DEFINE_LIST "")
foreach(module ${modules})
	if(JUCE_MODULE_AVAILABLE_${module})
		string(APPEND JUCE_MODULE_AVAILABLE_DEFINE_LIST "#define JUCE_MODULE_AVAILABLE_${module}\t1\n")
	else()
		string(APPEND JUCE_MODULE_AVAILABLE_DEFINE_LIST "#define JUCE_MODULE_AVAILABLE_${module}\t0\n")
	endif()
endforeach()

set(JUCE_APPCONFIG_H "${PROJECT_BINARY_DIR}/JuceLibraryCode/AppConfig.h")

configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/AppConfig.h.in" ${JUCE_APPCONFIG_H})

list(APPEND JUCE_INCLUDES "${PROJECT_BINARY_DIR}/JuceLibraryCode")

###############################################################################
# juce_common pseudo target

set(JUCE_COMMON_SOURCES ${JUCE_APPCONFIG_H} ${JUCE_HEADER_H})
add_library(juce_common INTERFACE)
target_include_directories(juce_common INTERFACE ${JUCE_INCLUDES})
target_compile_features(juce_common INTERFACE cxx_auto_type cxx_constexpr)
target_sources(juce_common INTERFACE ${JUCE_COMMON_SOURCES})
source_group(JuceLibraryCode FILES ${JUCE_COMMON_SOURCES})
set_target_properties(juce_common PROPERTIES
    INTERFACE_COMPILE_DEFINITIONS         NDEBUG
    INTERFACE_COMPILE_DEFINITIONS_DEBUG   DEBUG
    INTERFACE_COMPILE_DEFINITIONS_RELEASE NDEBUG
)


###############################################################################


set(JUCE_AVAILABLE_MODULES "")
set(JUCE_SOURCES ${JUCE_APPCONFIG_H} ${JUCE_HEADER_H})
set(JUCE_OSXFrameworks "")
set(JUCE_iOSFrameworks "")


###############################################################################
# add_library for each module
foreach(module ${modules})
	if(NOT JUCE_MODULE_AVAILABLE_${module})
		continue()
	endif()

	set(current_module_prefix "${JUCE_MODULES_PREFIX}/${module}")
	set(${module}_HEADER "${current_module_prefix}/${module}.h")
    set(${module}_MM "${current_module_prefix}/${module}.mm")
    set(${module}_CPP "${current_module_prefix}/${module}.cpp")

	if(EXISTS ${${module}_MM} OR EXISTS ${${module}_CPP})
		if(APPLE AND EXISTS ${${module}_MM})
            set(cpp_or_mm_ext "mm")
		else()
            set(cpp_or_mm_ext "cpp")
		endif()
	else() # it might be the audio_plugin_client module
		continue()
	endif()

    list(APPEND JUCE_AVAILABLE_MODULES ${module})

    set(${module}_IMPLEMENTATION "${PROJECT_BINARY_DIR}/JuceLibraryCode/include_${module}.${cpp_or_mm_ext}")
    configure_file("${CMAKE_CURRENT_LIST_DIR}/templates/include_juce_module.cpp.in" "${${module}_IMPLEMENTATION}")

    set(${module}_SOURCES "${${module}_IMPLEMENTATION}")
    list(APPEND JUCE_SOURCES ${${module}_SOURCES})

	#message("add_library ${module}")
	add_library(${module} INTERFACE)
	target_sources(${module} INTERFACE ${${module}_SOURCES})
    target_link_libraries(${module} INTERFACE juce_common)

    # dependencies
	set(properties dependencies OSXFrameworks iOSFrameworks linuxLibs)
	foreach(property ${properties})
		juce_module_get_array_property(${module}_${property} ${property} ${${module}_HEADER})
	endforeach()
    target_link_libraries(${module} INTERFACE "${${module}_dependencies}")

	# platform specific
	if(MACOSX)
		set(${module}_frameworks "")
		foreach(framework ${${module}_OSXFrameworks})
			list(APPEND ${module}_frameworks "-framework ${framework}")
		endforeach()
		target_link_libraries(${module} INTERFACE "${${module}_frameworks}")

	    list(APPEND JUCE_OSXFrameworks ${${module}_frameworks})
	elseif(IOS)
		set(${module}_frameworks "")
		foreach(framework ${module}_iOSFrameworks})
			list(APPEND ${module}_frameworks "-framework ${framework}")
		endforeach()
		target_link_libraries(${module} INTERFACE "${${module}_frameworks}")

	    list(APPEND JUCE_iOSFrameworks ${${module}_frameworks})
	endif()
endforeach()


###############################################################################
# juce target 

add_library(juce INTERFACE)
foreach(module ${JUCE_AVAILABLE_MODULES})
    target_link_libraries(juce INTERFACE "${module}")
endforeach()

source_group(JuceLibraryCode FILES ${JUCE_SOURCES})
