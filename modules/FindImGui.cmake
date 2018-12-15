#.rst:
# Find ImGui
# -------------
#
# Finds the ImGui library. This module defines:
#
#  ImGui_FOUND                - True if ImGui library is found
#  ImGui::ImGui               - ImGui imported target
#
# Additionally these variables are defined for internal usage:
#
#  ImGui_INCLUDE_DIR          - Include dir
#

#
#   This file is part of Magnum.
#
#   Copyright © 2010, 2011, 2012, 2013, 2014, 2015, 2016, 2017, 2018
#             Vladimír Vondruš <mosra@centrum.cz>
#   Copyright © 2018 Jonathan Hale <squareys@googlemail.com>
#
#   Permission is hereby granted, free of charge, to any person obtaining a
#   copy of this software and associated documentation files (the "Software"),
#   to deal in the Software without restriction, including without limitation
#   the rights to use, copy, modify, merge, publish, distribute, sublicense,
#   and/or sell copies of the Software, and to permit persons to whom the
#   Software is furnished to do so, subject to the following conditions:
#
#   The above copyright notice and this permission notice shall be included
#   in all copies or substantial portions of the Software.
#
#   THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#   IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#   FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
#   THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#   LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
#   FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
#   DEALINGS IN THE SOFTWARE.
#

find_package(imgui CONFIG QUIET)
if(imgui_FOUND)
    if(NOT TARGET ImGui::ImGui)
        add_library(ImGui::ImGui INTERFACE IMPORTED)
        set_property(TARGET ImGui::ImGui APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES imgui::imgui)

        # Retrieve include directory for FindPackageHandleStandardArgs later
        get_target_property(ImGui_INCLUDE_DIR imgui::imgui
            INTERFACE_INCLUDE_DIRECTORIES)

        add_library(ImGui::Sources INTERFACE IMPORTED)
        set_property(TARGET ImGui::Sources APPEND PROPERTY
            INTERFACE_LINK_LIBRARIES ImGui::ImGui)
    endif()
else()
    # Disable the find root path here, it overrides the
    # CMAKE_FIND_ROOT_PATH_MODE_INCLUDE setting potentially set in
    # toolchains.
    find_path(ImGui_INCLUDE_DIR NAMES imgui.h HINTS "${IMGUI_DIR}"
        NO_CMAKE_FIND_ROOT_PATH)

    if(NOT TARGET ImGui::ImGui)
        add_library(ImGui::ImGui INTERFACE IMPORTED)
        set_property(TARGET ImGui::ImGui APPEND PROPERTY
            INTERFACE_INCLUDE_DIRECTORIES "${ImGui_INCLUDE_DIR}")

        # Handle export and import of imgui symbols via IMGUI_API definition
        # in visibility.h of Magnum ImGuiIntegration.
        set_property(TARGET ImGui::ImGui APPEND PROPERTY INTERFACE_COMPILE_DEFINITIONS
            "IMGUI_USER_CONFIG=\"Magnum/ImGuiIntegration/visibility.h\"")
    endif()
endif()

# Find components
foreach(_component IN LISTS ImGui_FIND_COMPONENTS)

    if(_component STREQUAL "Sources")
        set(ImGui_Sources_FOUND TRUE)
        set(ImGui_SOURCES )

        foreach(_file imgui imgui_widgets imgui_draw imgui_demo)
            # Disable the find root path here, it overrides the
            # CMAKE_FIND_ROOT_PATH_MODE_INCLUDE setting potentially set in
            # toolchains.
            find_file(ImGui_${_file}_SOURCE NAMES ${_file}.cpp
                HINTS "${IMGUI_DIR}" NO_CMAKE_FIND_ROOT_PATH)
            list(APPEND ImGui_SOURCES ${ImGui_${_file}_SOURCE})

            if(NOT ImGui_${_file}_SOURCE)
                set(ImGui_Sources_FOUND FALSE)
                break()
            endif()

            # Hide warnings from imgui source files

            # Handle export and import of imgui symbols via IMGUI_API definition
            # in visibility.h of Magnum ImGuiIntegration.
            set_property(SOURCE ${ImGui_${_file}_SOURCE} APPEND PROPERTY COMPILE_DEFINITIONS
                "IMGUI_USER_CONFIG=\"Magnum/ImGuiIntegration/visibility.h\"")

            # GCC- and Clang-specific flags
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR (CMAKE_CXX_COMPILER_ID MATCHES "(Apple)?Clang"
                AND NOT CMAKE_CXX_SIMULATE_ID STREQUAL "MSVC") OR CORRADE_TARGET_EMSCRIPTEN)
                set_property(SOURCE ${ImGui_${_file}_SOURCE} APPEND_STRING PROPERTY COMPILE_FLAGS
                    " -Wno-old-style-cast -Wno-zero-as-null-pointer-constant")
                set_property(SOURCE ${ImGui_${_file}_SOURCE} PROPERTY CORRADE_USE_PEDANTIC_FLAGS OFF)
                set_property(SOURCE ${ImGui_${_file}_SOURCE} PROPERTY CORRADE_USE_PEDANTIC_DEFINITIONS OFF)
            endif()

            # GCC-specific flags
            if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
                 set_property(SOURCE ${ImGui_${_file}_SOURCE} APPEND_STRING PROPERTY COMPILE_FLAGS
                     " -Wno-double-promotion")
            endif()
        endforeach()

        if(NOT TARGET ImGui::Sources)
            add_library(ImGui::Sources INTERFACE IMPORTED)
            set_property(TARGET ImGui::Sources APPEND PROPERTY
                INTERFACE_SOURCES "${ImGui_SOURCES}")
            set_property(TARGET ImGui::Sources APPEND PROPERTY
                INTERFACE_LINK_LIBRARIES ImGui::ImGui)

            set(ImGui_Sources_FOUND ${ImGui_SOURCES})
        else()
            set(ImGui_Sources_FOUND TRUE)
        endif()
    endif()
endforeach()


include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(ImGui
    REQUIRED_VARS ImGui_INCLUDE_DIR HANDLE_COMPONENTS)

unset(_FIND_SOURCES)