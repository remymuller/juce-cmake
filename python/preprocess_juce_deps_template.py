###############################################################################
# 
#   Converts juce module description into cmake rules.
#
#   Each Juce module header contains a description of its module dependencies
#   as well as OSX and iOS frameworks that needs to be linked.
#   
#   This sections is preprocessed and a cmake library target is generated for
#   each module
# 
###############################################################################


import glob
import os
import re
from string import Template

modules = glob.glob("../JUCE/modules/*")

class MyTemplate(Template):
    delimiter = "%"

module_template = MyTemplate(
"""###############################################################################
# %{module_name}
###############################################################################


set(%{module_name}_DEPENDENCIES
    %{module_dependencies}
)

if(APPLE)
    set(%{module_name}_SOURCES
        %{module_sources}
    )
else()
    set(%{module_name}_SOURCES
        %{module_sources}
    )
endif()
                
add_library(%{module_name} ${%{module_name}_SOURCES})
target_link_libraries(%{module_name} ${%{module_name}_DEPENDENCIES})
target_compile_definitions(%{module_name} PUBLIC -DJUCE_GLOBAL_MODULE_SETTINGS_INCLUDED)
target_include_directories(%{module_name} PUBLIC ${JUCE_INCLUDES})
source_group(%{module_name} FILES ${%{module_name}_SOURCES})


""")

with open("juce_modules.cmake", 'w') as out:
    out.write("""###############################################################################
# 
#   JUCE 
# 
###############################################################################


set(CMAKE_CXX_STANDARD 14)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(JUCE_INCLUDES PUBLIC ${PROJECT_SOURCE_DIR}/../JUCE/modules/)


""")

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

                module_dependencies = "\n    ".join(deps)
                
                module_sources = "${PROJECT_SOURCE_DIR}/%s\n        ${PROJECT_SOURCE_DIR}/%s" % (module_header, module_cpp)
                if os.path.exists(module_mm):
                    module_sources_apple = "${PROJECT_SOURCE_DIR}/%s\n        ${PROJECT_SOURCE_DIR}/%s" % (module_header, module_mm)
                else:
                    module_sources_apple = module_sources

                env = dict(
                    module_name = module_name, 
                    module_dependencies=module_dependencies,
                    module_sources=module_sources,
                    module_sources_apple=module_sources
                    )
                module_str = module_template.substitute(env)
                if os.path.exists(module_mm) or os.path.exists(module_cpp):
                    out.write(module_str)



