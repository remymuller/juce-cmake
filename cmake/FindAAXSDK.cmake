# - Try to find the AAX SDK
# Once done this will define
# 
#  AAXSDK_FOUND - system has AAXSDK SDK
#  AAXSDK_ROOT - the AAXSDK SDK root directory

set(results "")
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
	message("AAXSDK_SEARCH_PATHS_HINT ${f}")
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
