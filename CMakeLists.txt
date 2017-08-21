###############################################################################
# 
#	JUCE static library
# 
###############################################################################


cmake_minimum_required(VERSION 3.0)

project(juce)

# TODO: option(JUCE_USE_SINGLE_TARGET "" OFF) # generate one target per module or only one global target

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

if(APPLE)
	if(${CMAKE_SYSTEM_NAME} MATCHES "Darwin")
		set(MACOSX true)
	else() 
		set(IOS true)	
	endif()
endif()

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${PROJECT_SOURCE_DIR}/cmake")
include(JuceOptions)
include(JuceModules)