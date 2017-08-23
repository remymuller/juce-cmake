cmake_minimum_required(VERSION 3.0)
project(juce)

set(CMAKE_MODULE_PATH "${CMAKE_MODULE_PATH};${PROJECT_SOURCE_DIR}/cmake")

add_subdirectory(examples/HelloWorld "${PROJECT_BINARY_DIR}/HelloWorld")
