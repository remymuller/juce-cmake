cmake_minimum_required(VERSION 3.0)

project(HelloWorld)

find_package(JUCE REQUIRED 
	COMPONENTS 
		juce_core
		juce_data_structures
		juce_events
		juce_graphics
		juce_gui_basics
		juce_gui_extra
)

set(SOURCES
	Main.cpp
	MainComponent.h
	MainComponent.cpp
)

# set(JUCE_PROJECT_NAME HelloWorld)
add_executable(HelloWorld ${SOURCES})
set_target_properties(HelloWorld PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(HelloWorld ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
