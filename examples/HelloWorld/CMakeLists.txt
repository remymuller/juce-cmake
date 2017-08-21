cmake_minimum_required(VERSION 3.0)

project(HelloWorld)

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
	Main.cpp
	MainComponent.h
	MainComponent.cpp
)

set(JUCE_PROJECT_NAME HelloWorld)
set(JUCE_MODULE_AVAILABLE_juce_opengl OFF)
add_subdirectory("${PROJECT_SOURCE_DIR}/../../" "${PROJECT_BINARY_DIR}/juce")
add_executable(HelloWorld ${SOURCES})
source_group(Source FILES ${SOURCES})

# link with individual modules
target_link_libraries(HelloWorld 
	juce_core 
	juce_data_structures
	juce_events 
	juce_graphics 
	juce_gui_basics 
	juce_gui_extra
)

set_target_properties(HelloWorld PROPERTIES MACOSX_BUNDLE true)
target_compile_features(HelloWorld INTERFACE cxx_auto_type cxx_constexpr)
