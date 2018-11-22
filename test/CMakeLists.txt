cmake_minimum_required(VERSION 3.0)

project(JUCE)

set(CMAKE_MODULE_PATH "${PROJECT_SOURCE_DIR}/../cmake; ${CMAKE_MODULE_PATH};")

macro(add_project path)
	string(MAKE_C_IDENTIFIER ${path} JUCE_CURRENT_TARGET_PREFIX)
	add_subdirectory("${path}" "${PROJECT_BINARY_DIR}/${path}")
endmacro()

add_project("examples/HelloWorld")
add_project("examples/audio plugin demo")
add_project("examples/audio plugin host")
add_project("examples/PluckedStringsDemo")
add_project("examples/AnimationAppExample")
add_project("examples/Demo")
add_project("examples/DSPDemo")
#add_project("examples/MidiTest")
add_project("examples/OpenGLAppExample")
add_project("extras/binarybuilder")
add_project("extras/AudioPerformanceTest")
