juce-cmake
==========

This project is another attempt at providing [CMake][cmake] support for the [JUCE][juce] library. 

Compared to other similar projects, this one autogenerates the list of JUCE modules by inspecting its repository.
It is also inspired by the standard CMake module [FindBoost][find_boost].

Thanks to the simple [JUCE Module Format][juce_module_format] specifications, intermodule and external dependencies are resolved by inspecting each module header file for properties and configuration flags. This is similar to the way the Projucer handles modules.

Compared to [JUCE.cmake][juce_dot_cmake] which is similar and more advanced, there is a number of design differences:
* It is meant to be used with pure CMake based projects without having to rely on the Projucer to bootstrap projects.
* It relies on [find_package][find_package](JUCE COMPONENTS ${modules}) to configure [JUCE][juce].
* It uses CMake [INTERFACE][interface] targets for each module to propagate the transitive dependencies.
* It tries to only rely on standard CMake constructs as much as possible.

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

[cmake]: https://cmake.org
[juce]: http://www.juce.com
[juce_dot_cmake]: https://github.com/McMartin/JUCE.cmake 
[find_boost]: https://cmake.org/cmake/help/latest/module/FindBoost.html
[juce_module_format]: https://github.com/WeAreROLI/JUCE/blob/master/modules/JUCE%20Module%20Format.txt
[find_package]: https://cmake.org/cmake/help/latest/command/find_package.html
[interface]: https://cmake.org/cmake/help/latest/command/add_library.html?highlight=interface#interface-libraries
