import glob
import os
import re

modules = glob.glob("../JUCE/modules/*")

with open("juce_modules.cmake", 'w') as out:
	out.write("set(CMAKE_CXX_STANDARD 14)\n")
	out.write("set(CMAKE_CXX_STANDARD_REQUIRED ON)\n")
	out.write("set(JUCE_INCLUDES PUBLIC ${PROJECT_SOURCE_DIR}/../JUCE/modules/)\n")
	out.write("\n")

	for path in modules:
		#path = os.path.abspath(path)
		if os.path.isdir(path):
			base,module_name = os.path.split(path)
			print module_name

			module_header_abs = os.path.abspath(os.path.join(path, module_name + ".h"))
			module_header = os.path.join(path, module_name + ".h")
			module_cpp = os.path.join(path, module_name + ".cpp")
			module_mm = os.path.join(path, module_name + ".mm")

			print module_header_abs
			with open(module_header_abs) as f:
				content = f.read()
				content = content.split("BEGIN_JUCE_MODULE_DECLARATION")[1]
				content = content.split("END_JUCE_MODULE_DECLARATION")[0]
				print content

				deps = content.split("dependencies:")[1].split("\n")[0].strip()
				deps = [s.strip(",") for s in deps.split()]

				print "deps:", deps

				# TODO use jinja
				out.write("# %s\n\n" % module_name)
				out.write("set(%s_DEPENDENCIES\n\t%s)\n" % (module_name, "\n\t".join(deps)))
				
				if os.path.exists(module_mm):
					out.write("if(APPLE)\n")
					out.write("\tset(%s_SOURCES\n\t\t%s\n\t\t%s)\n" % (module_name, "${PROJECT_SOURCE_DIR}/" + module_header, "${PROJECT_SOURCE_DIR}/" + module_mm))
					out.write("else()\n")
					out.write("\tset(%s_SOURCES\n\t\t%s\n\t\t%s)\n" % (module_name, "${PROJECT_SOURCE_DIR}/" + module_header, "${PROJECT_SOURCE_DIR}/" + module_cpp))
					out.write("endif()\n")
				else:
					out.write("set(%s_SOURCES\n\t%s\n\t%s)\n" % (module_name, "${PROJECT_SOURCE_DIR}/" + module_header, "${PROJECT_SOURCE_DIR}/" + module_cpp))

				if os.path.exists(module_mm) or os.path.exists(module_cpp):
					out.write("add_library(%s ${%s_SOURCES})\n" % (module_name, module_name))
					out.write("target_link_libraries(%s ${%s_DEPENDENCIES})\n" % (module_name, module_name))
					out.write("target_compile_definitions(%s PUBLIC -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED)\n" % module_name)
					out.write("target_include_directories(%s PUBLIC ${JUCE_INCLUDES})\n" % module_name)
					out.write("source_group(%s FILES ${%s_SOURCES})" % (module_name, module_name))
				out.write("\n\n")



