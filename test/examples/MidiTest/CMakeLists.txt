cmake_minimum_required(VERSION 3.0)

project(MidiTest)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(JUCE REQUIRED 
	COMPONENTS 
		juce_audio_basics
		juce_audio_devices
		juce_audio_formats
		juce_audio_processors
		juce_audio_utils
		juce_core
		juce_data_structures
		juce_dsp
		juce_events
		juce_graphics
		juce_gui_basics
		juce_gui_extra
)

set(SOURCES
Source/Main.cpp
Source/MainComponent.cpp
Source/MainComponent.h
)

add_executable(${PROJECT_NAME} ${SOURCES})
set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(${PROJECT_NAME} ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
