# - Try to find the VST3 SDK
# Once done this will define
# 
#  VST3SDK_FOUND - system has VST3 SDK
#  VST3SDK_HOME - the VST3 SDK root directory
#  VST2SDK_HOME - the VST2 SDK root directory
#  VSTSDK_HOME - the VST SDK root directory

# TODO inherit the paths from somewhere


set(results "")

# if the variable is already defined, set it as the first hint
if(DEFINED VST3SDK_HOME)
	set(results ${results} "${VST3SDK_HOME}/../")
endif()

foreach(basedir "${CMAKE_CURRENT_SOURCE_DIR}/" "${CMAKE_CURRENT_LIST_DIR}/" "$ENV{HOME}/" "C:/")
	foreach(level "" "../" "../../")
		foreach(suffix "" "SDKs/")
            foreach(subfolder "" "VST_SDK/")
                foreach(pattern "" "vstsdk2.4" "VST2_SDK" "vst*" "VST*")
				    file(GLOB results1 "${basedir}${level}${suffix}${subfolder}${pattern}")
				    set(results ${results} ${results1})
                endforeach()
            endforeach()
		endforeach()
	endforeach()
endforeach()

foreach(f ${results})
  if(IS_DIRECTORY ${f})
    set(VSTSDK_SEARCH_PATHS_HINT ${VSTSDK_SEARCH_PATHS_HINT} ${f})
  endif()
endforeach()

find_path(VSTSDK_HOME
	  VST3_SDK/public.sdk/source/vst3stdsdk.cpp
	HINTS
    	${VSTSDK_SEARCH_PATHS_HINT}
)

find_path(VST2SDK_HOME
	  pluginterfaces/vst2.x/aeffect.h
	  public.sdk/source/vst2.x/audioeffectx.h
	  public.sdk/source/vst2.x/audioeffect.h
	HINTS
    	${VSTSDK_SEARCH_PATHS_HINT}
)

set(VST3SDK_HOME "${VSTSDK_HOME}/VST3_SDK" CACHE PATH "path to the VST3_SDK")
set(VST2SDK_HOME "${VST2SDK_HOME}" CACHE PATH "path to the VST2_SDK")

# handle the QUIETLY and REQUIRED arguments and set AAXSDK_FOUND to TRUE if 
# all listed variables are TRUE
include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(VST3SDK DEFAULT_MSG VSTSDK_HOME)
mark_as_advanced(VST3SDK_HOME)
mark_as_advanced(VST2SDK_HOME)
mark_as_advanced(VSTSDK_HOME)

# export a VST3SDK::VST3SDK target
if(VST3SDK_FOUND)
	if(NOT TARGET VST3SDK::VST3SDK)
    	add_library(VST3SDK::VST3SDK INTERFACE IMPORTED)
    	set_target_properties(VST3SDK::VST3SDK PROPERTIES
        	INTERFACE_INCLUDE_DIRECTORIES "${VST3SDK_HOME};${VST2SDK_HOME}"
    	)
	endif()
endif()
