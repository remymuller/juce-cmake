cmake_minimum_required(VERSION 3.0)
project(JuceDemoPlugin)

find_package(JUCE REQUIRED 
    COMPONENTS 
        juce_audio_basics
        juce_audio_devices
        juce_audio_formats
        juce_audio_plugin_client
        juce_audio_processors
        juce_audio_utils
        juce_core
        juce_data_structures
        juce_events
        juce_graphics
        juce_gui_basics
        juce_gui_extra
)

set(SOURCES
    Source/PluginEditor.cpp
    Source/PluginEditor.h
    Source/PluginProcessor.cpp
    Source/PluginEditor.h
    Source/SineWaveSynth.h
)

set(common_definitions
    JUCE_QUICKTIME=0
    JUCE_PLUGINHOST_VST=0
    JUCE_PLUGINHOST_AU=0
)

find_package(AAXSDK REQUIRED)

juce_add_audio_plugin(
    PRODUCT_NAME                ${PROJECT_NAME}
    VERSION                     1.0.0
    PLUGIN_NAME                 "Juce Demo Plugin"
    PLUGIN_DESC                 "Juce Demo Plugin"
    PLUGIN_MANUFACTURER         "ROLI Ltd."
    PLUGIN_MANUFACTURER_EMAIL   "info@juce.com"
    PLUGIN_MANUFACTURER_CODE    ROLI
    PLUGIN_CODE                 Jcdm
    PLUGIN_IS_SYNTH             0
    PLUGIN_IS_MIDI_EFFECT       0
    PLUGIN_WANTS_MIDI_IN        1
    PLUGIN_PRODUCES_MIDI_OUT    1
    PLUGIN_EDITOR_REQUIRES_KEYS 1
    ENABLE_IAA                  1
    PLUGIN_AU_EXPORT_PREFIX     JuceDemoProjectAU
    PLUGIN_AU_VIEW_CLASS        JuceDemoProjectAU_V1
    COMPANY_NAME                "ROLI Ltd."
    COMPANY_WEBSITE             www.juce.com
    AAX_IDENTIFIER              com.yourcompany.JuceDemoPlugin
    AAX_CATEGORY                AAX_ePlugInCategory_Dynamics
    AAX_SDK                     "${AAXSDK_ROOT}"
    BUNDLE_IDENTIFIER           com.juce.JuceDemoPlugin
    FORMATS                     VST AU Standalone AAX # VST3 AUv3
    DEFINITIONS                 ${common_definitions}
    SOURCES                     ${SOURCES}
    LIBRARIES                   ${JUCE_LIBRARIES}
)

source_group(Source FILES ${SOURCES})




