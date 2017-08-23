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

# set(CMAKE_CXX_STANDARD 14)
# set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
	Main.cpp
	MainComponent.h
	MainComponent.cpp
)

# set(JUCE_PROJECT_NAME HelloWorld)
# set(JUCE_MODULE_AVAILABLE_juce_opengl OFF)
add_executable(HelloWorld ${SOURCES})
source_group(Source FILES ${SOURCES})
target_link_libraries(HelloWorld ${JUCE_LIBRARIES})

# set_target_properties(HelloWorld PROPERTIES MACOSX_BUNDLE true)
# target_compile_features(HelloWorld INTERFACE cxx_auto_type cxx_constexpr)
