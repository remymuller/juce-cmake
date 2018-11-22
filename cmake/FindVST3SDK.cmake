# - Try to find the VST3 SDK
# Once done this will define
# 
#  VST3SDK_FOUND - system has VST3 SDK
#  VST3SDK_ROOT - the VST3 SDK root directory
#  VST2SDK_ROOT - the VST3 SDK root directory
#  VSTSDK_ROOT - the VST3 SDK root directory

set(results "")
foreach(basedir "${CMAKE_CURRENT_SOURCE_DIR}/" "${CMAKE_CURRENT_LIST_DIR}/" "$ENV{HOME}/" "C:/")
	foreach(level "" "../" "../../")
		foreach(suffix "" "SDKs/")
            foreach(pattern "VST_SDK")
				file(GLOB results1 "${basedir}${level}${suffix}${pattern}*")
				set(results ${results} ${results1})
            endforeach()
		endforeach()
	endforeach()
endforeach()

foreach(f ${results})
  if(IS_DIRECTORY ${f})
    set(VSTSDK_SEARCH_PATHS_HINT ${VSTSDK_SEARCH_PATHS_HINT} ${f})
  endif()
endforeach()

find_path(VSTSDK_ROOT
	  VST3_SDK/public.sdk/source/vst3stdsdk.cpp
	HINTS
    	${VSTSDK_SEARCH_PATHS_HINT}
)

set(VST3SDK_ROOT "${VSTSDK_ROOT}/VST3_SDK")
set(VST2SDK_ROOT "${VSTSDK_ROOT}/VST2_SDK")

# handle the QUIETLY and REQUIRED arguments and set AAXSDK_FOUND to TRUE if 
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(VST3SDK DEFAULT_MSG VST3SDK_ROOT VST2SDK_ROOT VSTSDK_ROOT)
mark_as_advanced(VST3SDK_ROOT)
mark_as_advanced(VST2SDK_ROOT)
mark_as_advanced(VSTSDK_ROOT)

# export a VST3SDK::VST3SDK target
if(VST3SDK_FOUND)
	if(NOT TARGET VST3SDK::VST3SDK)
    	add_library(VST3SDK::VST3SDK INTERFACE IMPORTED)
    	set_target_properties(VST3SDK::VST3SDK PROPERTIES
        	INTERFACE_INCLUDE_DIRECTORIES "${VST3SDK_ROOT}"
    	)
	endif()
endif()
