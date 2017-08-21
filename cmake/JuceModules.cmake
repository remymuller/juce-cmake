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
        string(APPEND JUCE_MODULE_INCLUDES_LIST "#include <${module}/${module}.h\n")
    endif()
endforeach()


set(JUCE_HEADER_H "${PROJECT_BINARY_DIR}/JuceLibraryCode/JuceHeader.h")
configure_file("JuceHeader.h.in" ${JUCE_HEADER_H})


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

configure_file("AppConfig.h.in" ${JUCE_APPCONFIG_H})

list(APPEND JUCE_INCLUDES "${PROJECT_BINARY_DIR}/JuceLibraryCode")

###############################################################################
# juce_common pseudo target

add_library(juce_common INTERFACE)
target_include_directories(juce_common INTERFACE ${JUCE_INCLUDES})

set(JUCE_AVAILABLE_MODULES "")

set(JUCE_SOURCES ${APP_CONFIG_H} ${JUCE_HEADER_H})

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
    configure_file("include_juce_module.cpp.in" "${${module}_IMPLEMENTATION}")

    set_source_files_properties(${${module}_CPP} PROPERTIES HEADER_FILE_ONLY TRUE) # allows to not build it

    # TODO add mm or cpp without compiling
    set(${module}_SOURCES 
        "${${module}_HEADER}" 
        #"${${module}_CPP}" 
        "${${module}_IMPLEMENTATION}")

    if(JUCE_CMAKE_USE_SINGLE_TARGET)
        list(APPEND JUCE_SOURCES ${${module}_SOURCES})
        continue()
    else()
        source_group(src FILES ${${module}_SOURCES})
    endif()

	message("add_library ${module}")
	add_library(${module} ${${module}_SOURCES})

    target_link_libraries(${module} juce_common)

    # dependencies
	#juce_get_module_info(juce_current_module_info, ${${module}_HEADER})

	set(properties dependencies OSXFrameworks iOSFrameworks linuxLibs)
	foreach(property ${properties})
		juce_module_get_array_property(${module}_${property} ${property} ${${module}_HEADER})
		#message("\t${property}: ${${module}_${property}}")
	endforeach()
    #message("${module}_dependencies: ${${module}_dependencies}")
    target_link_libraries(${module} "${${module}_dependencies}")

	# platform specific
	if(MACOSX)
		set(${module}_frameworks "")
		foreach(framework in ${OSXFrameworks})
			list(APPEND ${module}_frameworks "-framework ${framework}")
		endforeach()
		target_link_libraries(${module} "${${module}_frameworks}")
	elseif(IOS)
		set(${module}_frameworks "")
		foreach(framework in ${iOSFrameworks})
			list(APPEND ${module}_frameworks "-framework ${framework}")
		endforeach()
		target_link_libraries(${module} "${${module}_frameworks}")
	endif()

	#target_compile_definitions(${module} PUBLIC -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED)
	#target_include_directories(${module} PUBLIC ${JUCE_INCLUDES})
endforeach()


###############################################################################
# juce target 

if(JUCE_CMAKE_USE_SINGLE_TARGET)
    add_library(juce ${JUCE_SOURCES})
    source_group(JuceLibraryCode FILES ${JUCE_SOURCES})
else()
    add_library(juce INTERFACE)
    foreach(module ${JUCE_AVAILABLE_MODULES})
        target_link_libraries(juce INTERFACE "${module}")
    endforeach()
endif()
