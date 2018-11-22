# - Try to find the AAX SDK
# Once done this will define
# 
#  AAXSDK_FOUND - system has AAX SDK
#  AAXSDK_ROOT - the AAX SDK root directory

set(results "")

# if the variable is already defined, set it as the first hint
if(DEFINED AAXSDK_ROOT)
	set(results ${results} "${AAXSDK_ROOT}")
endif()

foreach(basedir "${CMAKE_CURRENT_SOURCE_DIR}/" "${CMAKE_CURRENT_LIST_DIR}/" "$ENV{HOME}/" "C:/")
	foreach(level "" "../" "../../")
		foreach(suffix "" "SDKs/")
            foreach(pattern "AAX_SDK_2p3p1" "AAX_SDK" "AAX")
				file(GLOB results1 "${basedir}${level}${suffix}${pattern}*")
				set(results ${results} ${results1})
            endforeach()
		endforeach()
	endforeach()
endforeach()

foreach(f ${results})
  if(IS_DIRECTORY ${f})
    set(AAXSDK_SEARCH_PATHS_HINT ${AAXSDK_SEARCH_PATHS_HINT} ${f})
  endif()
endforeach()

find_path(AAXSDK_ROOT
	  Interfaces/AAX.h
	HINTS
    	${AAXSDK_SEARCH_PATHS_HINT}
)


# handle the QUIETLY and REQUIRED arguments and set AAXSDK_FOUND to TRUE if 
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(AAXSDK DEFAULT_MSG AAXSDK_ROOT)
mark_as_advanced(AAXSDK_ROOT)

# export an AAXSDK::AAXSDK target
if(AAXSDK_FOUND)
	set(AAXSDK_INCLUDE_DIRS 
        "${AAXSDK_ROOT}" 
        "${AAXSDK_ROOT}/Interfaces" 
        "${AAXSDK_ROOT}/Interfaces/ACF"
	)

    find_library(AAXSDK_LIB_DEBUG
        NAMES 
            libAAXLibrary_libcpp.a
            libAAXLibrary_libcpp.lib
        PATHS
            "${AAXSDK_ROOT}/Libs/Debug/"
        NO_DEFAULT_PATH
    )

    find_library(AAXSDK_LIB_RELEASE
        NAMES 
            libAAXLibrary_libcpp.a
            libAAXLibrary_libcpp.lib
        PATHS
            "${AAXSDK_ROOT}/Libs/Release/"
        NO_DEFAULT_PATH
    )

	if(NOT TARGET AAXSDK::AAXSDK)
    	add_library(AAXSDK::AAXSDK INTERFACE IMPORTED)
    	set_target_properties(AAXSDK::AAXSDK PROPERTIES
        	INTERFACE_INCLUDE_DIRECTORIES "${AAXSDK_INCLUDE_DIRS}"
    	)
    	set_target_properties(AAXSDK::AAXSDK PROPERTIES 
    		INTERFACE_LINK_LIBRARIES 
    		"$<IF:$<CONFIG:Debug>,${AAXSDK_LIB_DEBUG},${AAXSDK_LIB_RELEASE}>")
	endif()
endif()
