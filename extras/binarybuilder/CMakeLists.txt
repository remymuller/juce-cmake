
cmake_minimum_required(VERSION 3.0)

project(binarybuilder)

#set(JUCE_PROJECT_NAME ${PROJECT_NAME})
find_package(JUCE REQUIRED 
	COMPONENTS 
		juce_core
)

set(SOURCES
	Source/Main.cpp
)

add_executable(${PROJECT_NAME} ${SOURCES})
set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(${PROJECT_NAME} ${JUCE_LIBRARIES})
target_compile_definitions(${PROJECT_NAME} 
	PUBLIC 
		JUCE_ONLY_BUILD_CORE_LIBRARY=1
)
source_group(Source FILES ${SOURCES})
