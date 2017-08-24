"""

	For each .jucer file, generate a CMakeLists.txt

"""

import os
import fnmatch
import string
import xml.etree.ElementTree as ET


def jucer_get_modules(tree):
	"""
	"""
	root = tree.getroot()
	pass


def jucer_get_project_name(tree):
	"""
	"""
	root = tree.getroot()
	return root.attrib['name']


def jucer_get_sources(tree):
	"""
	"""
	sources = []
	root = tree.getroot()
	maingroup = root.find("MAINGROUP")
	groups = maingroup.findall("GROUP")
	for group in groups:
		files = group.findall("FILE")
		for file in files:
			filepath = file.attrib['file']
			sources.append(filepath)
	return "\n".join(sources)


cmakelists_template = """
cmake_minimum_required(VERSION 3.0)

set(ProjectName ${ProjectName})
project($${ProjectName})

set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(SOURCES
${Sources}
)

set(JUCE_PROJECT_NAME $${ProjectName})
#set(JUCE_MODULE_AVAILABLE_juce_opengl OFF)
add_subdirectory("$${PROJECT_SOURCE_DIR}/../../" "$${PROJECT_BINARY_DIR}/juce")
add_executable($${ProjectName} $${SOURCES})
source_group(Source FILES $${SOURCES})
target_link_libraries($${ProjectName} ${juce_modules})
set_target_properties($${ProjectName} PROPERTIES MACOSX_BUNDLE true)
target_compile_features($${ProjectName} INTERFACE cxx_auto_type cxx_constexpr)
"""


def process_jucer_file(jucer_file):
	base, file = os.path.split(jucer_file)
	print base, file

	# get info
	jucer_tree = ET.parse(jucer_file)
	modules = jucer_get_modules(jucer_tree)
	sources = jucer_get_sources(jucer_tree)
	project_name = jucer_get_project_name(jucer_tree)

	print sources

	# generate output
	out_file = os.path.join(base, "CMakelists.txt")
	with open(out_file, "w") as out:
		template = string.Template(cmakelists_template)
		text = template.substitute(dict(
			ProjectName="<ProjectName>",
			Sources=sources,
			juce_modules='""'
			))
		out.write(text)


jucer_files = []
for root, dirnames, filenames in os.walk('.'):
    for filename in fnmatch.filter(filenames, '*.jucer'):
        jucer_files.append(os.path.join(root, filename))


for jucer_file in jucer_files:
	process_jucer_file(jucer_file)


