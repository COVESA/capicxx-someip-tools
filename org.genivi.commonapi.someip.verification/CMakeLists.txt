cmake_minimum_required (VERSION 2.8.1)

PROJECT(libsomeipglue)

SET( ${PROJECT_NAME}_MAJOR_VERSION 3 )
SET( ${PROJECT_NAME}_MINOR_VERSION 1 )
SET( ${PROJECT_NAME}_PATCH_LEVEL 3 )

message("Project name: ${PROJECT_NAME}")

SET(PACKAGE_VERSION "${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}.${${PROJECT_NAME}_PATCH_LEVEL}")
SET(COMMONAPI_API_HEADER_VERSION ${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}) # used in *.cmake.in

##############################################################################

# create the commandline variables:
OPTION(BUILD_SHARED_LIBS "Set to OFF to build static libraries" ON )
message("BUILD_SHARED_LIBS is set to value: ${BUILD_SHARED_LIBS}")

OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message("USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif(NOT CMAKE_BUILD_TYPE)

SET(COMMONAPI_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI install path of the cmake files")
SET(COMMONAPI_SOMEIP_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI-SomeIP install path of the cmake files")
SET(COMMONAPI_SOMEIP_TOOL_GENERATOR "na" CACHE STRING "CommonAPI-SomeIP-Tools generator install path")
SET(COMMONAPI_TEST_FIDL_PATH "na" CACHE STRING "Path to directory with test fidl/fdepl files for code generation")

if("${COMMONAPI_TOOL_GENERATOR}" STREQUAL "")
    message(FATAL_ERROR "The file path for the commonapi_generator needs to be specified! Use '-DCOMMONAPI_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_TOOL_GENERATOR specified: ${COMMONAPI_TOOL_GENERATOR}")
endif()

if("${COMMONAPI_SOMEIP_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi_someip_generator needs to be specified! Use '-DCOMMONAPI_SOMEIP_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_SOMEIP_TOOL_GENERATOR specified: ${COMMONAPI_SOMEIP_TOOL_GENERATOR}")
endif()

message("Build type: ${CMAKE_BUILD_TYPE}")

##############################################################################
# add COMMONAPI install path to cmake find root path

if(NOT "${COMMONAPI_CMAKE_INSTALL_PATH}" STREQUAL "na")
  set( CMAKE_FIND_ROOT_PATH ${COMMONAPI_CMAKE_INSTALL_PATH};${CMAKE_FIND_ROOT_PATH} )
endif()
if(NOT "${COMMONAPI_SOMEIP_CMAKE_INSTALL_PATH}" STREQUAL "na")
  set( CMAKE_FIND_ROOT_PATH ${COMMONAPI_SOMEIP_CMAKE_INSTALL_PATH};${CMAKE_FIND_ROOT_PATH} )
endif()
message("CMAKE_FIND_ROOT_PATH: ${CMAKE_FIND_ROOT_PATH}")

if ("${USE_INSTALLED_COMMONAPI}" STREQUAL "ON")
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    FIND_PACKAGE(CommonAPI-SomeIP REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
    FIND_PACKAGE(vsomeip REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
else()
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(CommonAPI-SomeIP REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(vsomeip REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
endif()

message("CommonAPI_CONSIDERED_CONFIGS: ${CommonAPI_CONSIDERED_CONFIGS}")
message("COMMONAPI_INCLUDE_DIRS: ${COMMONAPI_INCLUDE_DIRS}")
message("CommonAPI-SomeIP_CONSIDERED_CONFIGS: ${CommonAPI-SomeIP_CONSIDERED_CONFIGS}")
message("COMMONAPI_SOMEIP_INCLUDE_DIRS: ${COMMONAPI_SOMEIP_INCLUDE_DIRS}")

##############################################################################
# generate code from fidl and fdepl

# TODO check if generators are executable as otherwise they fail silently

file(GLOB FIDL_FILES "${COMMONAPI_TEST_FIDL_PATH}/*.fidl")
message("FIDL_FILES: ${FIDL_FILES}")
execute_process(
    COMMAND ${COMMONAPI_TOOL_GENERATOR} --dest src-gen --skel ${FIDL_FILES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

file(GLOB FDEPL_FILES "fidl/*.fdepl")
message("FDEPL_FILES: ${FDEPL_FILES}")
execute_process(
    COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} --dest src-gen ${FDEPL_FILES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

##############################################################################
# someip glue build section

# OS
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set (OS "LINUX")
    set (DL_LIBRARY "dl")
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set (OS "FREEBSD")
    set(DL_LIBRARY "")
endif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")

if (MSVC)
# Visual C++ is not always sure whether he is really C++
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DBOOST_LOG_DYN_LINK -DUSE_VSOMEIP_STATISTICS -D_CRT_SECURE_NO_WARNINGS /EHsc -DCOMMONAPI_INTERNAL_COMPILATION")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -DBOOST_LOG_DYN_LINK -DUSE_VSOMEIP_STATISTICS -D_CRT_SECURE_NO_WARNINGS -DCOMMONAPI_INTERNAL_COMPILATION")
else()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D${OS} -DUSE_VSOMEIP_STATISTICS -DBOOST_LOG_DYN_LINK -D_GLIBCXX_USE_NANOSLEEP -pthread -g -std=c++0x -O0 -Wno-deprecated-register")
endif()

message("Compiler options: ${CMAKE_CXX_FLAGS}")

include_directories(
    src
    src-gen
    ${COMMONAPI_INCLUDE_DIRS}
    ${VSOMEIP_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
)

if (MSVC)
set (DERIVED_TYPE_SRC "src-gen/v1_0/commonapi/datatypes/derived/TestInterface.cpp")
set (TARGET_LIBRARIES "libboost_system-vc120-mt-gd-1_56")
endif ()

# source files
file(GLOB GLUE_SRCS
    "src-gen/v1_0/commonapi/communication/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/datatypes/primitive/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/datatypes/advanced/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/datatypes/combined/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/datatypes/derived/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/performance/primitive/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/performance/complex/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/runtime/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/threading/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/stability/sp/*SomeIP*.cpp"
    "src-gen/v1_0/commonapi/stability/mp/*SomeIP*.cpp"
	${DERIVED_TYPE_SRC}
)

# Boost
find_package( Boost 1.54 COMPONENTS system thread log REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

link_directories(
	${Boost_LIBRARY_DIR}
)

# CommonAPI-SomeIP library
add_library(SomeIPGlue ${GLUE_SRCS})
set_target_properties(SomeIPGlue PROPERTIES VERSION 0.0.0 SOVERSION 0 LINKER_LANGUAGE C)
target_link_libraries(SomeIPGlue CommonAPI-SomeIP ${TARGET_LIBRARIES})

##############################################################################
# exporting, configuring and installing of cmake files

# Add all targets to the build-tree export set
export(TARGETS SomeIPGlue
  FILE "${PROJECT_BINARY_DIR}/SomeIPGlueTargets.cmake")

# Export the package for use from the build-tree
# (this registers the build-tree with a global CMake-registry)
export(PACKAGE SomeIPGlue)

# Create the SomeIPGlueConfig.cmake and SomeIPGlueConfigVersion files ...
# ... for the build tree
set(CONF_INCLUDE_DIRS "${PROJECT_SOURCE_DIR}/src")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SomeIPGlueConfig.cmake.in
  "${PROJECT_BINARY_DIR}/SomeIPGlueConfig.cmake" @ONLY)

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/cmake/SomeIPGlueConfigVersion.cmake.in
  "${PROJECT_BINARY_DIR}/SomeIPGlueConfigVersion.cmake" @ONLY)

##############################################################################
# maintainer-clean
add_custom_target(maintainer-clean COMMAND rm -rf *)
