cmake_minimum_required(VERSION 3.0)

project(OpenGLAppExample)

find_package(JUCE REQUIRED 
	COMPONENTS 
		juce_audio_basics
		juce_audio_devices
		juce_audio_formats
		juce_audio_processors
		juce_core
		juce_cryptography
		juce_data_structures
		juce_events
		juce_graphics
		juce_gui_basics
		juce_gui_extra
		juce_opengl
		juce_video
)

set(SOURCES
	Source/MainComponent.cpp
	Source/Main.cpp
	JuceLibraryCode/BinaryData.h
	JuceLibraryCode/BinaryData.cpp
)

add_executable(${PROJECT_NAME} ${SOURCES})
set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(${PROJECT_NAME} ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
