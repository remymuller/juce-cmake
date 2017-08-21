juce-cmake
==========

This project is another attempt at providing CMake support for the [Juce][juce] library. 

Compared to other similar projects, this one autogenerates the list of juce modules by inspecting its repository. 

Thanks to the simple juce module format, intermodule and external dependencies are resolved by parsing the module info from each module header file.

Example
-------

```cmake
cmake_minimum_required(VERSION 3.0)
project(HelloWorld)

add_subdirectory(<path/to/juce-cmake>)
add_executable(helloworld main.cpp)
target_link_libraries(helloworld juce)
```

[juce]: http://www.juce.com