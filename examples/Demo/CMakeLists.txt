cmake_minimum_required(VERSION 3.0)

project(JuceDemo)

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
		juce_box2d
)

set(SOURCES
Source/Demos/AnimationDemo.cpp
Source/Demos/AudioLatencyDemo.cpp
Source/Demos/AudioLiveScrollingDisplay.h
Source/Demos/AudioPlaybackDemo.cpp
Source/Demos/AudioRecordingDemo.cpp
Source/Demos/AudioSettingsDemo.cpp
Source/Demos/AudioSynthesiserDemo.cpp
Source/Demos/Box2DDemo.cpp
Source/Demos/CameraDemo.cpp
Source/Demos/ChildProcessDemo.cpp
Source/Demos/CodeEditorDemo.cpp
Source/Demos/ComponentTransformsDemo.cpp
Source/Demos/CryptographyDemo.cpp
Source/Demos/DialogsDemo.cpp
Source/Demos/FlexBoxDemo.cpp
Source/Demos/FontsDemo.cpp
Source/Demos/GraphicsDemo.cpp
Source/Demos/ImagesDemo.cpp
Source/Demos/JavaScript.cpp
Source/Demos/KeyMappingsDemo.cpp
Source/Demos/LiveConstantDemo.cpp
Source/Demos/LookAndFeelDemo.cpp
Source/Demos/MDIDemo.cpp
Source/Demos/MidiDemo.cpp
Source/Demos/MultithreadingDemo.cpp
Source/Demos/MultiTouch.cpp
Source/Demos/NetworkingDemo.cpp
Source/Demos/OpenGLDemo.cpp
Source/Demos/OpenGLDemo2D.cpp
Source/Demos/PropertiesDemo.cpp
Source/Demos/SystemInfoDemo.cpp
Source/Demos/TimersAndEventsDemo.cpp
Source/Demos/UnitTestsDemo.cpp
Source/Demos/ValueTreesDemo.cpp
Source/Demos/VideoDemo.cpp
Source/Demos/WavefrontObjParser.h
Source/Demos/WebBrowserDemo.cpp
Source/Demos/WidgetsDemo.cpp
Source/Demos/WindowsDemo.cpp
Source/Demos/XMLandJSONDemo.cpp
Source/DemoUtilities.h
Source/IntroScreen.cpp
Source/JuceDemoHeader.h
Source/Main.cpp
Source/MainWindow.cpp
Source/MainWindow.h
JuceLibraryCode/BinaryData.h
JuceLibraryCode/BinaryData.cpp
)

add_executable(${PROJECT_NAME} ${SOURCES})
set_target_properties(${PROJECT_NAME} PROPERTIES MACOSX_BUNDLE true)
target_link_libraries(${PROJECT_NAME} ${JUCE_LIBRARIES})
source_group(Source FILES ${SOURCES})
