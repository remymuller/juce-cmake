###############################################################################
# 
#	JUCE static library
# 
###############################################################################


cmake_minimum_required(VERSION 3.0)

project(juce)

option(JUCE_CMAKE_USE_SINGLE_TARGET "generate one target per module or only one global target" OFF) 

set(JUCE_PROJECT_NAME "NewProject" CACHE STRING "JUCE project's name") # 

# TODO add cache options for paths to ASIOSDK, VSTSDK... etc

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