###############################################################################
# AppConfig Options

Option(JUCE_ASIO "" OFF)

Option(JUCE_WASAPI "" OFF)

Option(JUCE_WASAPI_EXCLUSIVE "" OFF)

Option(JUCE_DIRECTSOUND "" OFF)

Option(JUCE_ALSA "" OFF)

Option(JUCE_JACK "" OFF)

Option(JUCE_USE_ANDROID_OPENSLES "" OFF)

Option(JUCE_USE_WINRT_MIDI "" OFF)

#==============================================================================
# juce_audio_formats flags:

Option(JUCE_USE_FLAC "" OFF)

Option(JUCE_USE_OGGVORBIS "" OFF)

Option(JUCE_USE_MP3AUDIOFORMAT "" OFF)

Option(JUCE_USE_LAME_AUDIO_FORMAT "" OFF)

Option(JUCE_USE_WINDOWS_MEDIA_FORMAT "" OFF)

#==============================================================================
# juce_audio_processors flags:

Option(JUCE_PLUGINHOST_VST "" OFF)

Option(JUCE_PLUGINHOST_VST3 "" OFF)

Option(JUCE_PLUGINHOST_AU "" OFF)

#==============================================================================
# juce_core flags:

Option(JUCE_FORCE_DEBUG "" OFF)

Option(JUCE_LOG_ASSERTIONS "" OFF)

Option(JUCE_CHECK_MEMORY_LEAKS "" OFF)

Option(JUCE_DONT_AUTOLINK_TO_WIN32_LIBRARIES "" OFF)

Option(JUCE_INCLUDE_ZLIB_CODE "" OFF)

Option(JUCE_USE_CURL "" OFF)

Option(JUCE_CATCH_UNHANDLED_EXCEPTIONS "" OFF)

Option(JUCE_ALLOW_STATIC_NULL_VARIABLES "" OFF)

#==============================================================================
# juce_events flags:

Option(JUCE_EXECUTE_APP_SUSPEND_ON_IOS_BACKGROUND_TASK "" OFF)

#==============================================================================
# juce_graphics flags:

Option(JUCE_USE_COREIMAGE_LOADER "" OFF)

Option(JUCE_USE_DIRECTWRITE "" OFF)

#==============================================================================
# juce_gui_basics flags:

Option(JUCE_ENABLE_REPAINT_DEBUGGING "" OFF)

Option(JUCE_USE_XSHM "" OFF)

Option(JUCE_USE_XRENDER "" OFF)

Option(JUCE_USE_XCURSOR "" OFF)

#==============================================================================
# juce_gui_extra flags:

Option(JUCE_WEB_BROWSER "" OFF)

Option(JUCE_ENABLE_LIVE_CONSTANT_EDITOR "" OFF)

#==============================================================================
# juce_video flags:

Option(JUCE_USE_CAMERA "" OFF)