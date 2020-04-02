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
# One can set the JUCE_DIR_HINT variable to give a specific location to look 
# for JUCE files.
# 
# This module finds headers and requested component libraries. 
# Results are reported in variables::
# 
#   JUCE_FOUND              - True if headers and requested modules were found
#   JUCE_INCLUDE_DIR        - JUCE include directories
#   JUCE_ROOT_DIR           - path to JUCE 
#   JUCE_LIBRARIES          - JUCE component libraries to be linked
#   JUCE_MODULES            - list of resolved modules
#   JUCE_SOURCES            - JUCE library sources
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

cmake_policy(SET CMP0057 NEW) # support for IN_LIST operator

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
    mark_as_advanced(JUCE_${module}_minimumCppStandard)
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
                if(${JUCE_CONFIG_${_flag}} MATCHES ON)
                    set(value 1)
                elseif(${JUCE_CONFIG_${_flag}} MATCHES OFF)
                    set(value 0)
                endif()

                if(DEFINED value)
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

        # TODO: look for ${JUCE_MODULES_PATHS} and populate with ${JUCE_MODULES_PREFIX}
        # TODO: also use find_path
        set(JUCE_${module}_HEADER "${JUCE_MODULES_PREFIX}/${module}/${module}.h" CACHE PATH "Header for JUCE module ${module}")
        mark_as_advanced(JUCE_${module}_HEADER)

        juce_module_get_info(${module})

        juce_module_set_platformlibs(${module})
        juce_module_get_config_flags(${module})


        # debug
        # set(properties 
        #   dependencies 
        #   OSXFrameworks 
        #   iOSFrameworks 
        #   linuxLibs
        # )
        # foreach(property ${properties})
        #   message("JUCE_${module}_${property}:\t${JUCE_${module}_${property}}")
        # endforeach()

        # generate immutable INTERFACE IMPORTED library for module
        if(NOT TARGET ${module})

            # force missing dependencies
            if(${module} MATCHES juce_audio_plugin_client)
                if(APPLE AND NOT IOS)
                    list(APPEND JUCE_${module}_platformlibs ${JUCE_LIB_AudioUnit})
                    list(APPEND JUCE_${module}_platformlibs ${JUCE_LIB_CoreAudioKit})
                endif()
            endif()

            add_library(${module} INTERFACE IMPORTED)
            set_property(TARGET ${module} PROPERTY INTERFACE_INCLUDE_DIRECTORIES ${JUCE_${module}_searchpaths})
            set_property(TARGET ${module} PROPERTY INTERFACE_LINK_LIBRARIES 
                    juce_common
                    "${JUCE_${module}_dependencies}"
                    "${JUCE_${module}_platformlibs}"
            )

            # Show juce sources but do not compile them
            file(GLOB_RECURSE source_module
                     "${JUCE_MODULES_PREFIX}/${module}/*.c*"
                     "${JUCE_MODULES_PREFIX}/${module}/*.h*"
                     "${JUCE_MODULES_PREFIX}/${module}/*.mm"
                     "${JUCE_MODULES_PREFIX}/${module}/*.txt"
                     "${JUCE_MODULES_PREFIX}/${module}/*.java")
             target_sources(${module} INTERFACE ${source_module})
             set_source_files_properties(${source_module} PROPERTIES HEADER_FILE_ONLY TRUE)

            get_filename_component(JUCE_PARENT_DIR ${JUCE_ROOT_DIR} DIRECTORY)
            source_group(TREE "${JUCE_PARENT_DIR}" FILES ${source_module})

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

# hard coded add_dependencies
if(APPLE AND NOT IOS)
    find_library(JUCE_LIB_AudioUnit AudioUnit)
    find_library(JUCE_LIB_CoreAudioKit CoreAudioKit)
    mark_as_advanced(JUCE_LIB_AudioUnit)
    mark_as_advanced(JUCE_LIB_CoreAudioKit)
endif()

function(juce_dec_to_hex dec_value out_hex_value)
  if(dec_value EQUAL 0)
    set(${out_hex_value} "0x0" PARENT_SCOPE)
    return()
  endif()

  if(dec_value LESS 0)
    math(EXPR dec_value "2147483647 ${dec_value} + 1")
  endif()

  while(dec_value GREATER 0)
    math(EXPR hex_unit "${dec_value} & 15")
    if(hex_unit LESS 10)
      set(hex_char ${hex_unit})
    else()
      math(EXPR hex_unit "${hex_unit} + 87")
      string(ASCII ${hex_unit} hex_char)
    endif()
    set(hex_value "${hex_char}${hex_value}")
    math(EXPR dec_value "${dec_value} >> 4")
  endwhile()

  set(${out_hex_value} "0x${hex_value}" PARENT_SCOPE)
endfunction()

function(juce_version_to_dec version out_dec_value)
    string(REPLACE "." ";" segments "${version}")
    list(LENGTH segments segments_size)
    while(segments_size LESS 3)
        list(APPEND segments 0)
        math(EXPR segments_size "${segments_size} + 1")
    endwhile()
    list(GET segments 0 major)
    list(GET segments 1 minor)
    list(GET segments 2 patch)
    math(EXPR dec_value "(${major} << 16) + (${minor} << 8) + ${patch}")
    if(segments_size GREATER 3)
        list(GET segments 3 revision)
        math(EXPR dec_value "${dec_value} << 8 + ${revision}")
    endif()

    set(${out_dec_value} "${dec_value}" PARENT_SCOPE)
endfunction()


function(juce_version_to_hex version out_hex_value)
    juce_version_to_dec("${version}" dec_value)
    juce_dec_to_hex("${dec_value}" hex_value)
    set(${out_hex_value} "${hex_value}" PARENT_SCOPE)
endfunction()

#------------------------------------------------------------------------------
# First find JUCE
# TODO: look for juce_core/juce_core.h instead 
find_path(JUCE_ROOT_DIR 
    "modules/JUCE Module Format.txt"
    HINTS
        ${PROJECT_SOURCE_DIR}/../
        ${PROJECT_SOURCE_DIR}/../JUCE
        ${PROJECT_SOURCE_DIR}/JUCE
        ${CMAKE_CURRENT_LIST_DIR}/../../JUCE
        ${CMAKE_CURRENT_LIST_DIR}/../JUCE
    DOC 
        "JUCE library directory"
)

if(NOT EXISTS ${JUCE_ROOT_DIR})
    message(FATAL_ERROR "JUCE not found.")
endif() 

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
# inherit VERSION from outside scope
if(DEFINED VERSION)
    set(JUCE_PROJECT_VERSION "${VERSION}")
elseif(DEFINED PROJECT_VERSION)
    set(JUCE_PROJECT_VERSION ${PROJECT_VERSION})
else()
    set(JUCE_PROJECT_VERSION "1.0.0")
endif()
juce_version_to_hex(${JUCE_PROJECT_VERSION} JUCE_PROJECT_VERSION_HEX)
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

    # get all module files
    file(GLOB _module_FILES 
        LIST_DIRECTORIES false
        "${JUCE_MODULES_PREFIX}/${module}/${module}*.*")

    # look for unique basename 
    set(module_files_basenames "")
    foreach(_file ${_module_FILES})
        get_filename_component(module_source_basename ${_file} NAME_WE)
        list(APPEND module_files_basenames ${module_source_basename})
    endforeach()
    list(REMOVE_DUPLICATES module_files_basenames)


    #foreach(cpp_file ${JUCE_${module}_CPP_FILES})
        #get_filename_component(module_source_basename ${cpp_file} NAME_WE)
    foreach(module_source_basename ${module_files_basenames})

        if(APPLE)            
            if("${JUCE_MODULES_PREFIX}/${module}/${module_source_basename}.mm" IN_LIST _module_FILES)
                set(_ext "mm")
            endif()

            if("${JUCE_MODULES_PREFIX}/${module}/${module_source_basename}.r" IN_LIST _module_FILES)
                set(_ext "r")
            endif()
        endif()

        if(NOT DEFINED _ext)
            if("${JUCE_MODULES_PREFIX}/${module}/${module_source_basename}.cpp" IN_LIST _module_FILES)
                set(_ext "cpp")
            else()
                continue()
            endif()
        endif()

        #message(STATUS "JUCE: Using ${module_source_basename}.${_ext}")

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
#message("using CXX: ${JUCE_CXX_STANDARD}")


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


# export some helper functions

# first remember where we are
set(JUCE_CMAKE_MODULE_DIR ${CMAKE_CURRENT_LIST_DIR} CACHE INTERNAL "")

macro(juce_get_PluginVSTCategoryString var)
    if(PLUGIN_IS_SYNTH)
        set(${var} kPlugCategSynth)
    else()
        set(${var} kPlugCategEffect)
    endif()
endmacro()

macro(juce_get_AUMainTypeEnum var)
    if(PLUGIN_IS_MIDI_EFFECT)
        # Unfortunately, Rez uses a header where kAudioUnitType_MIDIProcessor is undefined
        # Use aumi instead.
        # set(${var} 'aumi')
        set(${var} kAudioUnitType_MIDIProcessor)
    elseif(PLUGIN_IS_SYNTH)
        set(${var} kAudioUnitType_MusicDevice)
    elseif(PLUGIN_WANTS_MIDI_IN)
        set(${var} kAudioUnitType_MusicEffect)
    else()
        set(${var} kAudioUnitType_Effect)
    endif()
endmacro()

macro(juce_get_AUMainTypeCode var)
    if(PLUGIN_IS_MIDI_EFFECT)
        set(${var} aumi)
    elseif(PLUGIN_IS_SYNTH)
        set(${var} aumu)
    elseif(PLUGIN_WANTS_MIDI_IN)
        set(${var} aumf)
    else()
        set(${var} aufx)
    endif()
endmacro()

macro(juce_get_IAATypeCode var)
    if(PLUGIN_WANTS_MIDI_IN)
        if(PLUGIN_IS_SYNTH)
            set(${var} auri)
        else()
            set(${var} aurm)
        endif()
    else()
        if(PLUGIN_IS_SYNTH)
            set(${var} aurg)
        else()
            set(${var} aurx)
        endif()
    endif()
endmacro()

function(juce_four_chars_to_hex value out_hex_value)
  foreach(ascii_code RANGE 1 127)
    list(APPEND all_ascii_codes ${ascii_code})
  endforeach()
  string(ASCII ${all_ascii_codes} all_ascii_chars)

  string(STRIP "${value}" four_chars)
  string(SUBSTRING "${four_chars}" 0 4 four_chars)
  set(dec_value 0)
  foreach(index 0 1 2 3)
    string(SUBSTRING "${four_chars}" ${index} 1 ascii_char)
    string(FIND "${all_ascii_chars}" "${ascii_char}" ascii_code)
    if(ascii_code EQUAL -1)
      message(FATAL_ERROR "${value} cannot contain non-ASCII characters")
    endif()
    math(EXPR dec_value "(${dec_value} << 8) | ((${ascii_code} + 1) & 255)")
  endforeach()

  juce_dec_to_hex("${dec_value}" hex_value)
  set(${out_hex_value} "${hex_value}" PARENT_SCOPE)
endfunction()

function(juce_set_bundle_properties target)
    if(APPLE)
        set_target_properties(${target} 
            PROPERTIES 
                OUTPUT_NAME ${PRODUCT_NAME}
                XCODE_ATTRIBUTE_PRODUCT_NAME ${PRODUCT_NAME}
                BUNDLE true
                XCODE_ATTRIBUTE_MACH_O_TYPE mh_bundle
                XCODE_ATTRIBUTE_WARNING_CFLAGS "-Wmost -Wno-four-char-constants -Wno-unknown-pragmas"
                XCODE_ATTRIBUTE_GENERATE_PKGINFO_FILE "YES"
                XCODE_ATTRIBUTE_DEPLOYMENT_LOCATION YES
                XCODE_ATTRIBUTE_DSTROOT "/"
                XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${BUNDLE_IDENTIFIER}
                MACOSX_BUNDLE_GUI_IDENTIFIER ${BUNDLE_IDENTIFIER}
                MACOSX_BUNDLE_BUNDLE_VERSION ${VERSION}
                BUNDLE_EXTENSION "${OSX_EXTENSION}"
                XCODE_ATTRIBUTE_WRAPPER_EXTENSION "${OSX_EXTENSION}"
                XCODE_ATTRIBUTE_INSTALL_PATH "${OSX_INSTALL_PATH}"
                XCODE_ATTRIBUTE_INFOPLIST_FILE ${PLIST}
                MACOSX_BUNDLE_INFO_PLIST ${PLIST}
                XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION ${VERSION}
        )
    endif()
endfunction()

function(juce_set_app_bundle_properties target)
    if(APPLE)
        set_target_properties(${target} 
            PROPERTIES 
                OUTPUT_NAME ${PRODUCT_NAME}
                XCODE_ATTRIBUTE_PRODUCT_NAME ${PRODUCT_NAME}
                MACOSX_BUNDLE true
                XCODE_ATTRIBUTE_WARNING_CFLAGS "-Wmost -Wno-four-char-constants -Wno-unknown-pragmas"
                XCODE_ATTRIBUTE_GENERATE_PKGINFO_FILE "YES"
                XCODE_ATTRIBUTE_DEPLOYMENT_LOCATION YES
                XCODE_ATTRIBUTE_DSTROOT "/"
                XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER ${BUNDLE_IDENTIFIER}
                MACOSX_BUNDLE_GUI_IDENTIFIER ${BUNDLE_IDENTIFIER}
                MACOSX_BUNDLE_BUNDLE_VERSION ${VERSION}
                XCODE_ATTRIBUTE_INSTALL_PATH "${OSX_INSTALL_PATH}"
                XCODE_ATTRIBUTE_INFOPLIST_FILE ${PLIST}
                MACOSX_BUNDLE_INFO_PLIST ${PLIST}
                XCODE_ATTRIBUTE_CURRENT_PROJECT_VERSION ${VERSION}
        )
    endif()
endfunction()

function(juce_add_vst target product_name sources)
    set(OSX_EXTENSION "vst")
    set(OSX_INSTALL_PATH "$(HOME)/Library/Audio/Plug-Ins/VST/")
    set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-VST.plist.in")
    set(PLIST "${CMAKE_BINARY_DIR}/JuceLibraryCode/${target}_Info.plist")

    if(APPLE)
        configure_file("${PLIST_IN}" "${PLIST}" @ONLY)
    endif()

    if(NOT TARGET VST3SDK::VST3SDK)
        find_package(VST3SDK REQUIRED)
    endif()

    add_library(${target} MODULE ${sources})
    set_target_properties(${target} 
        PROPERTIES 
        PROJECT_LABEL "${product_name} VST"
        # OUTPUT_NAME "${product_name}"
    )
    target_link_libraries(${target} PUBLIC VST3SDK::VST3SDK) 
    juce_set_bundle_properties(${target})
endfunction()


function(juce_add_au target product_name sources)
    set(OSX_EXTENSION "component")
    set(OSX_INSTALL_PATH "$(HOME)/Library/Audio/Plug-Ins/Components/")
    set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-AU.plist.in")
    set(PLIST "${CMAKE_BINARY_DIR}/JuceLibraryCode/${target}_Info.plist")
    juce_get_AUMainTypeEnum(AU_TYPE)
    juce_get_AUMainTypeCode(AU_TYPE_CODE)

    configure_file("${PLIST_IN}" "${PLIST}" @ONLY)

    add_library(${target} MODULE ${sources})
    set_target_properties(${target} 
        PROPERTIES 
        PROJECT_LABEL "${product_name} AU"
        # OUTPUT_NAME "${product_name}"
    )
    juce_set_bundle_properties(${target})

    add_custom_command(
        TARGET ${target} 
        POST_BUILD
        COMMAND killall -9 AudioComponentRegistrar
        COMMAND auval -v ${AU_TYPE_CODE} ${PLUGIN_CODE} ${PLUGIN_MANUFACTURER_CODE}
    )
endfunction()


function(juce_add_aax target product_name sources)
    set(OSX_EXTENSION "aaxplugin")
    set(OSX_INSTALL_PATH "/Library/Application Support/Avid/Audio/Plug-Ins/")
    set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-AAX.plist.in")
    set(PLIST "${CMAKE_BINARY_DIR}/JuceLibraryCode/${target}_Info.plist")
    set(aax_plugin_path "${product_name}.aaxplugin")

    if(APPLE)
        configure_file("${PLIST_IN}" "${PLIST}" @ONLY)
    endif()

    add_library(${target} MODULE ${sources})
    set_target_properties(${target} 
        PROPERTIES 
        PROJECT_LABEL "${product_name} AAX"
        # OUTPUT_NAME "${product_name}"
        # AAX_PLUGIN_PATH "${aax_plugin_path}" #TODO export this on the target in order to know where the bundle is
    )
    juce_set_bundle_properties(${target})

    if(NOT TARGET AAXSDK::AAXSDK)
        find_package(AAXSDK REQUIRED)
    endif()
    target_link_libraries(${target} PUBLIC AAXSDK::AAXSDK) 

    if(MSVC)
        set_target_properties(${target} 
            PROPERTIES 
                SUFFIX ".aaxdll"
        )

        set(working_dir "${CMAKE_CURRENT_BINARY_DIR}")

        if(AAXSDK_X64)
            set(aax_plugin_dest_path "${aax_plugin_path}/Contents/x64")
            set(aax_plugin_install_path "$(CommonProgramW6432)/Avid/Audio/Plug-Ins/${product_name}.aaxplugin")
        else()
            set(aax_plugin_dest_path "${aax_plugin_path}/Contents/Win32")
            set(aax_plugin_install_path "$(CommonProgramFiles)/Avid/Audio/Plug-Ins/${product_name}.aaxplugin")
        endif()

        file(TO_NATIVE_PATH ${aax_plugin_dest_path} aax_plugin_dest_path)
        file(TO_NATIVE_PATH ${AAXSDK_HOME}/Utilities/PlugIn.ico aax_ico_path)
        add_custom_command(TARGET ${target} PRE_BUILD 
            COMMAND ${CMAKE_COMMAND} -E make_directory "${aax_plugin_dest_path}"
            COMMAND call "\"${AAXSDK_CREATE_PACKAGE}\"" "\"${aax_plugin_dest_path}\"" "\"${aax_ico_path}\"" 
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/$(Configuration)"
        )

        add_custom_command(TARGET ${target} POST_BUILD 
            COMMAND ${CMAKE_COMMAND} -E copy "\"$<TARGET_FILE:${target}>\"" "\"${aax_plugin_dest_path}/${product_name}.aaxplugin\""
            COMMAND xcopy "\"${aax_plugin_path}\"" "\"${aax_plugin_install_path}\""  /E /I /K /Y /R 
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/$(Configuration)"
        )
    endif()
endfunction()


function(juce_add_vst3 target product_name sources)
    set(OSX_EXTENSION "vst3")
    set(OSX_INSTALL_PATH "$(HOME)/Library/Audio/Plug-Ins/VST3/")
    set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-VST3.plist.in")
    set(PLIST "${CMAKE_BINARY_DIR}/JuceLibraryCode/${target}_Info.plist")

    if(NOT TARGET VST3SDK::VST3SDK)
        find_package(VST3SDK REQUIRED)
    endif()

    if(APPLE)
       configure_file("${PLIST_IN}" "${PLIST}" @ONLY)
    endif()

    add_library(${target} MODULE ${sources})
    juce_set_bundle_properties(${target})
    set_target_properties(${target} 
        PROPERTIES 
        PROJECT_LABEL "${product_name} VST3"
        # OUTPUT_NAME "${product_name}"
    )
    if(MSVC)
        set(vst3_plugin_path "${product_name}.vst3")
        set_target_properties(${target} 
            PROPERTIES 
                SUFFIX ".vst3dll"
        )

        if (CMAKE_SIZEOF_VOID_P EQUAL 8)
            set(vst3_plugin_dest_path "${vst3_plugin_path}/Contents/x86_64-win")
            set(vst3_plugin_install_path "$(CommonProgramW6432)/VST3/${product_name}.vst3")
        else()
            set(vst3_plugin_dest_path "${vst3_plugin_path}/Contents/x86-win")
            set(vst3_plugin_install_path "$(CommonProgramFiles)/VST3/${product_name}.vst3")
        endif()

        add_custom_command(TARGET ${target} PRE_BUILD 
            COMMAND ${CMAKE_COMMAND} -E make_directory "\"${vst3_plugin_path}/Resources\""
            COMMAND ${CMAKE_COMMAND} -E make_directory "\"${vst3_plugin_dest_path}\""
            COMMAND ${CMAKE_COMMAND} -E copy "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/desktop.ini.in" "${vst3_plugin_path}/desktop.ini"
            COMMAND ${CMAKE_COMMAND} -E copy "${VST3SDK_HOME}/doc/artwork/VST_Logo_Steinberg.ico" "${vst3_plugin_path}/PlugIn.ico"
            COMMAND attrib +s ${vst3_plugin_path}/desktop.ini
            COMMAND attrib +s ${vst3_plugin_path}/PlugIn.ico
            COMMAND attrib +s ${vst3_plugin_path}
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/$(Configuration)"
        )
        add_custom_command(TARGET ${target} POST_BUILD 
            COMMAND ${CMAKE_COMMAND} -E copy "\"$<TARGET_FILE:${target}>\"" "\"${vst3_plugin_dest_path}/${vst3_plugin_path}\""
            COMMAND xcopy "\"${vst3_plugin_path}\"" "\"${vst3_plugin_install_path}\""  /O /X /E /H /K /Y /I /C /Q /R
            WORKING_DIRECTORY "${CMAKE_CURRENT_BINARY_DIR}/$(Configuration)"
        )
    endif()

    target_link_libraries(${target} PUBLIC VST3SDK::VST3SDK) 
endfunction()


function(juce_add_standalone target product_name sources)
    if(IOS)
        set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-Standalone_Plugin.plist.in")
    else()
        set(PLIST_IN "${JUCE_CMAKE_MODULE_DIR}/FindJuceTemplates/Info-Standalone_iOS.plist.in")
    endif()
    set(PLIST "${CMAKE_BINARY_DIR}/JuceLibraryCode/${target}_Info.plist")

    if(APPLE)
        configure_file("${PLIST_IN}" "${PLIST}" @ONLY)
    endif()

    add_executable(${target} ${sources})
    set_target_properties(${target} 
        PROPERTIES 
        PROJECT_LABEL "${product_name} Standalone"
        # OUTPUT_NAME "${product_name}"
    )
    juce_set_app_bundle_properties(${target})

    if(MSVC)
        set_target_properties(${target} 
            PROPERTIES 
            WIN32_EXECUTABLE true
        )
    endif()
endfunction()



function(juce_generate_plugin_definitions var)
    set(${var}
         JucePlugin_Build_VST=${BUILD_VST}
         JucePlugin_Build_VST3=${BUILD_VST3}           
         JucePlugin_Build_AU=${BUILD_AU}               
         JucePlugin_Build_AUv3=${BUILD_AUv3}            
         JucePlugin_Build_RTAS=${BUILD_RTAS}            
         JucePlugin_Build_AAX=${BUILD_AAX}              
         JucePlugin_Build_Standalone=${BUILD_Standalone} 
         JucePlugin_Enable_IAA=${ENABLE_IAA}             
         JucePlugin_Name="${PLUGIN_NAME}"                   
         JucePlugin_Desc="${PLUGIN_DESC}"                   
         JucePlugin_Manufacturer="${PLUGIN_MANUFACTURER}"   
         JucePlugin_ManufacturerWebsite="${COMPANY_WEBSITE}"
         JucePlugin_ManufacturerEmail="${PLUGIN_MANUFACTURER_EMAIL}"      
         JucePlugin_ManufacturerCode='${PLUGIN_MANUFACTURER_CODE}'       
         JucePlugin_PluginCode='${PLUGIN_CODE}'
         # JucePlugin_VSTUniqueID='${PLUGIN_CODE}'
         JucePlugin_IsSynth=${PLUGIN_IS_SYNTH}
         JucePlugin_WantsMidiInput=${PLUGIN_WANTS_MIDI_IN}         
         JucePlugin_ProducesMidiOutput=${PLUGIN_PRODUCES_MIDI_OUT}
         JucePlugin_IsMidiEffect=${PLUGIN_IS_MIDI_EFFECT}
         JucePlugin_EditorRequiresKeyboardFocus=${PLUGIN_EDITOR_REQUIRES_KEYS}
         JucePlugin_Version=${VERSION}
         JucePlugin_VersionCode=${JUCE_PROJECT_VERSION_HEX}
         JucePlugin_VersionString="${VERSION}"
         JucePlugin_CFBundleIdentifier=${BUNDLE_IDENTIFIER}
    )

    if(${BUILD_VST})           
        juce_get_PluginVSTCategoryString(VST_TYPE)
        list(APPEND ${var}
            JucePlugin_VSTUniqueID=JucePlugin_PluginCode
            JucePlugin_VSTCategory=${VST_TYPE} 
        )
    endif()

    if(${BUILD_AU})
        juce_get_AUMainTypeEnum(AU_TYPE)
        juce_get_AUMainTypeCode(AU_TYPE_CODE)
        list(APPEND ${var}
             JucePlugin_AUMainType=${AU_TYPE}
             JucePlugin_AUSubType=JucePlugin_PluginCode
             JucePlugin_AUExportPrefix=${PLUGIN_AU_EXPORT_PREFIX}
             JucePlugin_AUExportPrefixQuoted="${PLUGIN_AU_EXPORT_PREFIX}"
             JucePlugin_AUManufacturerCode=JucePlugin_ManufacturerCode
        )
    endif()

    if(${BUILD_AAX})
        list(APPEND ${var}
            JucePlugin_AAXIdentifier=${AAX_IDENTIFIER}
            JucePlugin_AAXManufacturerCode=JucePlugin_ManufacturerCode
            JucePlugin_AAXProductId=JucePlugin_PluginCode
            JucePlugin_AAXCategory=${AAX_CATEGORY}
            JucePlugin_AAXDisableBypass=0
            JucePlugin_AAXDisableMultiMono=0
        )
    endif()

    if(${BUILD_VST3})
        list(APPEND ${var}
            JucePlugin_Vst3Category="${VST3_CATEGORY}"
        )
    endif()

    if(${BUILD_RTAS})
        list(APPEND ${var}
             JucePlugin_RTASCategory=ePlugInCategory_None
             JucePlugin_RTASManufacturerCode=JucePlugin_ManufacturerCode
             JucePlugin_RTASProductId=JucePlugin_PluginCode
             JucePlugin_RTASDisableBypass=0
             JucePlugin_RTASDisableMultiMono=0
        )
    endif()

    if(${ENABLE_IAA})
        juce_get_IAATypeCode(IAA_TYPE_CODE)
        juce_four_chars_to_hex(${IAA_TYPE_CODE} IAA_TYPE_HEX)
        #message("IAA_TYPE_CODE: ${IAA_TYPE_CODE} = ${IAA_TYPE_HEX}")

        list(APPEND ${var}
             JucePlugin_IAAType=IAA_TYPE_HEX #0x6175726d # 'aurm'
             JucePlugin_IAASubType=JucePlugin_PluginCode
             JucePlugin_IAAName="${COMPANY_NAME}: ${PLUGIN_NAME}"
        )
    endif()

    # foreach(definition ${${var}})
    #     message("${definition}")
    # endforeach()

    set(${var} ${${var}} PARENT_SCOPE)
endfunction()


function(juce_add_audio_plugin)
    # TODO: support RESOURCES
    # TODO: add optional VST_CATEGORY and AU_MAIN_TYPE to force plugin type
    # TODO: add optional PLUGIN_CHANNEL_CONFIGURATIONS

    set(required_properties
        PRODUCT_NAME 
        VERSION
        PLUGIN_NAME 
        PLUGIN_DESC
        PLUGIN_MANUFACTURER
        PLUGIN_MANUFACTURER_EMAIL
        PLUGIN_MANUFACTURER_CODE
        PLUGIN_CODE
        COMPANY_NAME
        COMPANY_WEBSITE
        BUNDLE_IDENTIFIER
    )

    set(optional_properties
        PLUGIN_IS_SYNTH
        PLUGIN_IS_MIDI_EFFECT
        PLUGIN_WANTS_MIDI_IN
        PLUGIN_PRODUCES_MIDI_OUT
        PLUGIN_EDITOR_REQUIRES_KEYS
        ENABLE_IAA
    )

    set(required_properties_AAX
        AAX_IDENTIFIER
        AAX_CATEGORY
        # AAX_SDK
    )

    set(required_properties_VST3
         #VST3_SDK
         VST3_CATEGORY
    )

    set(required_properties_AU
        PLUGIN_AU_EXPORT_PREFIX
        PLUGIN_AU_VIEW_CLASS
    )

    # parse arguments
    set(options "")
    set(oneValueArgs 
        PRODUCT_NAME 
        VERSION
        PLUGIN_NAME 
        PLUGIN_DESC
        PLUGIN_MANUFACTURER
        PLUGIN_MANUFACTURER_EMAIL
        PLUGIN_MANUFACTURER_CODE
        PLUGIN_CODE
        PLUGIN_IS_SYNTH
        PLUGIN_IS_MIDI_EFFECT
        PLUGIN_WANTS_MIDI_IN
        PLUGIN_PRODUCES_MIDI_OUT
        PLUGIN_EDITOR_REQUIRES_KEYS
        COMPANY_NAME
        COMPANY_WEBSITE
        BUNDLE_IDENTIFIER
        PLUGIN_AU_EXPORT_PREFIX
        PLUGIN_AU_VIEW_CLASS
        AAX_IDENTIFIER
        AAX_CATEGORY
        VST3_CATEGORY
        ENABLE_IAA
    )
    set(multiValueArgs FORMATS DEFINITIONS SOURCES LIBRARIES INCLUDES)
    set(allArgs ${options} ${oneValueArgs} ${multiValueArgs})
    cmake_parse_arguments(juce_add_audio_plugin 
        "${options}" 
        "${oneValueArgs}" 
        "${multiValueArgs}" 
        ${ARGN}
    )

    # validate arguments
    foreach(property ${required_properties})
        if(NOT DEFINED juce_add_audio_plugin_${property})
            message("juce_add_audio_plugin: property '${property}' is required")
            set(should_return true)
        endif()
    endforeach()

    foreach(format ${juce_add_audio_plugins_FORMATS})
        foreach(property ${required_properties_${format}})
            if(NOT DEFINED juce_add_audio_plugin_${property})
                message("juce_add_audio_plugin: property '${property}' is required for format '${format}'")
                set(should_return true)
            endif()
        endforeach()
    endforeach()

    if(should_return)
        return()
    endif()

    # import variables into local namespace
    foreach(arg ${allArgs})
        if(DEFINED juce_add_audio_plugin_${arg})
            set(${arg} ${juce_add_audio_plugin_${arg}})
        endif()
    endforeach()

    # set optional properties
    foreach(property ${optional_properties})
        if(DEFINED ${property})
            if(${property})
                set(${property} 1)
            else()
                set(${property} 0)
            endif()
        else()
            set(${property} 0)
        endif()
    endforeach()

    set(possible_formats VST AU VST3 AUv3 Standalone AAX RTAS)
    foreach(format ${possible_formats})
        if(${format} IN_LIST FORMATS)
            set(BUILD_${format} 1)
        else()
            set(BUILD_${format} 0)
        endif()
    endforeach()

	string(LENGTH ${PLUGIN_CODE} PLUGIN_CODE_LENGTH)
	string(LENGTH ${PLUGIN_MANUFACTURER_CODE} PLUGIN_MANUFACTURER_CODE_LENGTH)
	if (NOT (PLUGIN_CODE_LENGTH MATCHES "4") OR NOT (PLUGIN_MANUFACTURER_CODE_LENGTH MATCHES "4"))
		message(FATAL_ERROR "PLUGIN_CODE or PLUGIN_MANUFACTURER_CODE should be 4 chars length") 
	endif()
    juce_four_chars_to_hex(${PLUGIN_CODE} PLUGIN_CODE_INT)
    juce_four_chars_to_hex(${PLUGIN_MANUFACTURER_CODE} PLUGIN_MANUFACTURER_CODE_INT)

    # TOOD: create SharedCode target
    # for that we need that plugin specific code is not compiled in juce_audio_plugin_client
    # 

    # create one target per format
    foreach(format ${FORMATS})
        set(target_name ${PRODUCT_NAME}${format})
        
        # reset all formats
        foreach(format_ ${possible_formats})
            set(BUILD_${format_} 0)
        endforeach()

        # set enabled format
        set(BUILD_${format} 1)

        # generate the list of preprocessor defines
        unset(plugin_definitions)
        juce_generate_plugin_definitions(plugin_definitions)

        if(${format} MATCHES VST3)
            if(IOS)
                continue()
            endif()
            juce_add_vst3(${target_name} "${PRODUCT_NAME}" "${SOURCES}")
        elseif(${format} MATCHES VST)
            if(IOS)
                continue()
            endif()
            juce_add_vst(${target_name} "${PRODUCT_NAME}" "${SOURCES}")
        elseif(${format} MATCHES AAX)
            if(IOS)
                continue()
            endif()
            juce_add_aax(${target_name} "${PRODUCT_NAME}" "${SOURCES}" )
        elseif(${format} MATCHES Standalone)
            juce_add_standalone(${target_name} "${PRODUCT_NAME}" "${SOURCES}")
        elseif(${format} MATCHES AU)
            if(IOS)
                continue()
            endif()
            if(APPLE)            
                juce_add_au(${target_name} "${PRODUCT_NAME}" "${SOURCES}")
            else()
                continue()
            endif()
        else()
            message("juce_add_audio_plugins: format '${format}' not implemented")
            return()
        endif()
    
        target_compile_definitions(${target_name} PUBLIC ${plugin_definitions} ${DEFINITIONS})
        target_include_directories(${target_name} PUBLIC ${INCLUDES})
        target_link_libraries(${target_name} PUBLIC ${LIBRARIES})
    endforeach()
endfunction()
