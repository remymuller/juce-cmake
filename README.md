juce-cmake
==========

This project is another attempt at providing CMake support for the [Juce][juce] library. 

Compared to other similar projects, this one autogenerates the list of juce modules by inspecting its repository.
It is also inspired by the [FindBoost.cmake][find_boost]

Thanks to the simple juce module format, intermodule and external dependencies are resolved by parsing the module info from each module header file which is similar to how the Projucer handles modules.

Compared to [Juce.cmake][juce_cmake] which is similar and more advanced, there is a number of design differences:
	- It is meant to be used with pure cmake based projects without having to rely on the Projucer to bootstrap projects.
	- It relies on find_package(JUCE COMPONENTS).
	- It uses CMake INTERFACE targets for each module to propagate the transitive dependencies

Example
-------

```cmake
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

add_executable(HelloWorld ${SOURCES})
set_target_properties(HelloWorld PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(HelloWorld ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
```

[juce]: http://www.juce.com
[juce_cmake]: https://github.com/McMartin/JUCE.cmake 
[find_boost]: https://cmake.org/cmake/help/latest/module/FindBoost.html