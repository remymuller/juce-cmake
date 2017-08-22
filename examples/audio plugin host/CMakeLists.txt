cmake_minimum_required(VERSION 3.0)

project(PluginHost)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${PROJECT_SOURCE_DIR}/../../cmake")
set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

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

set(JUCE_PROJECT_NAME PluginHost)
set(JUCE_MODULE_AVAILABLE_juce_opengl ON)
set(JUCE_MODULE_AVAILABLE_juce_box2D OFF)
add_subdirectory("${PROJECT_SOURCE_DIR}/../../" "${PROJECT_BINARY_DIR}/juce")
#include(UseJuce)
add_executable(PluginHost ${SOURCES})
source_group(Source FILES ${SOURCES})
target_link_libraries(PluginHost juce)
target_compile_definitions(PluginHost PUBLIC JUCE_PLUGINHOST_VST=1)
set_target_properties(PluginHost PROPERTIES MACOSX_BUNDLE true)
target_compile_features(PluginHost INTERFACE cxx_auto_type cxx_constexpr)

source_group(JuceLibraryCode FILES ${JUCE_SOURCES})
