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
#     )                      # e.g. "core" for "juce_core"
# 
# This module finds headers and requested component libraries. 
# Results are reported in variables::
# 
#   JUCE_FOUND              - True if headers and requested modules were found
#   JUCE_INCLUDE_DIR        - JUCE include directories
#	JUCE_PATH				- path to JUCE 
#   JUCE_LIBRARIES          - JUCE component libraries to be linked
#   JUCE_<C>_FOUND          - True if component <C> was found (<C> is upper-case)
#   JUCE_<C>_LIBRARY        - Libraries to link for component <C>
#   JUCE_VERSION            - JUCE_VERSION value from boost/version.hpp
#   JUCE_MAJOR_VERSION      - JUCE major version number (X in X.y.z)
#   JUCE_MINOR_VERSION      - JUCE minor version number (Y in x.Y.z)
#   JUCE_SUBMINOR_VERSION   - JUCE subminor version number (Z in x.y.Z)

include(FindPackageHandleStandardArgs)

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

find_package_handle_standard_args(JUCE DEFAULT_MSG JUCE_INCLUDE_DIR)
