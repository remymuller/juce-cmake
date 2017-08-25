cmake_minimum_required(VERSION 3.0)

set(JUCE_PROJECT_NAME PluginHost)
project(${JUCE_PROJECT_NAME})

find_package(JUCE REQUIRED 
	COMPONENTS 
		juce_audio_basics
		juce_audio_devices
		juce_audio_formats
		juce_audio_processors
		juce_audio_utils
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
	Source/FilterGraph.cpp
	Source/FilterGraph.h
	Source/FilterIOConfiguration.cpp
	Source/FilterIOConfiguration.h
	Source/GraphEditorPanel.cpp
	Source/GraphEditorPanel.h
	Source/HostStartup.cpp
	Source/GraphEditorPanel.cpp
	Source/InternalFilters.cpp
	Source/InternalFilters.h
	Source/MainHostWindow.cpp
	Source/MainHostWindow.h
)

add_executable(${JUCE_PROJECT_NAME} ${SOURCES})
set_target_properties(${JUCE_PROJECT_NAME} PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(${JUCE_PROJECT_NAME} ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
target_compile_definitions(${JUCE_PROJECT_NAME} 
	PUBLIC 
		JUCE_PLUGINHOST_VST=1 
		JUCE_WASAPI=1 
		JUCE_DIRECTSOUND=1 
		#JUCE_PLUGINHOST_VST3=1
		#JUCE_PLUGINHOST_AU=1
		JUCE_ALSA=1
)

