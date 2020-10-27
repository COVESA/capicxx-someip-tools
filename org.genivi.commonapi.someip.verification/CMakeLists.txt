cmake_minimum_required (VERSION 2.8.1)

PROJECT(libsomeipglue)

SET( ${PROJECT_NAME}_MAJOR_VERSION 3 )
SET( ${PROJECT_NAME}_MINOR_VERSION 1 )
SET( ${PROJECT_NAME}_PATCH_LEVEL 12 )

message("Project name: ${PROJECT_NAME}")

SET(PACKAGE_VERSION "${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}.${${PROJECT_NAME}_PATCH_LEVEL}")
SET(COMMONAPI_API_HEADER_VERSION ${${PROJECT_NAME}_MAJOR_VERSION}.${${PROJECT_NAME}_MINOR_VERSION}) # used in *.cmake.in

##############################################################################

# create the commandline variables:
OPTION(BUILD_SHARED_LIBS "Set to OFF to build static libraries" ON )
message("BUILD_SHARED_LIBS is set to value: ${BUILD_SHARED_LIBS}")

OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message("USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

OPTION(USE_FILE "Set to OFF to disable file logging" OFF )
message(STATUS "USE_FILE is set to value: ${USE_FILE}")

OPTION(USE_CONSOLE "Set to OFF to disable console logging" OFF )
message(STATUS "USE_CONSOLE is set to value: ${USE_CONSOLE}")

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif(NOT CMAKE_BUILD_TYPE)

SET(COMMONAPI_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI install path of the cmake files")
SET(COMMONAPI_SOMEIP_CMAKE_INSTALL_PATH "na" CACHE STRING "CommonAPI-SomeIP install path of the cmake files")
SET(COMMONAPI_SOMEIP_TOOL_GENERATOR "na" CACHE STRING "CommonAPI-SomeIP-Tools generator install path")
SET(COMMONAPI_TEST_FIDL_PATH "na" CACHE STRING "Path to directory with test fidl/fdepl files for code generation")
SET(COMMONAPI_SRC_GEN_DEST "src-gen" CACHE STRING "Path to the destination directory of the generated sources")

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

message("The path to the destination directory of the generated sources is set to: ${COMMONAPI_SRC_GEN_DEST}")

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
    FIND_PACKAGE(vsomeip3 REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
else()
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(CommonAPI-SomeIP REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
    FIND_PACKAGE(vsomeip3 REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
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
    COMMAND ${COMMONAPI_TOOL_GENERATOR} --dest ${COMMONAPI_SRC_GEN_DEST} --skel ${FIDL_FILES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)

IF(USE_FILE)
  add_definitions(-DUSE_FILE)
ENDIF(USE_FILE)
IF(USE_CONSOLE)
  add_definitions(-DUSE_CONSOLE)
ENDIF(USE_CONSOLE)

SET(MAX_LOG_LEVEL "DEBUG" CACHE STRING "maximum log level")
message(STATUS "MAX_LOG_LEVEL is set to value: ${MAX_LOG_LEVEL}")
add_definitions(-DCOMMONAPI_LOGLEVEL=COMMONAPI_LOGLEVEL_${MAX_LOG_LEVEL})

if (MSVC)
    # Change possible backslashes to normal slashes
    string(REPLACE "\\" "/" COMMONAPI_TEST_FIDL_PATH ${COMMONAPI_TEST_FIDL_PATH})

    # GLIPCI-644, remove Drive when under windows
    string(SUBSTRING ${COMMONAPI_TEST_FIDL_PATH} 2 -1 COMMONAPI_TEST_FIDL_PATH)
endif()

# Create the fdepls files
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_communication.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_communication.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_advanced_bselective.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_advanced_bselective.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_advanced_managed.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_advanced_managed.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_advanced_extended.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_advanced_extended.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_advanced_polymorph.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_advanced_polymorph.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_datatypes_advanced.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_advanced.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_datatypes_combined.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_combined.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_datatypes_deployment.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_deployment.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_datatypes_derived.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_derived.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_datatypes_primitive.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_primitive.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_performance_complex.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_performance_complex.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_performance_primitive.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_performance_primitive.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_runtime.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_runtime.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_stability_sp.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_stability_sp.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/ti_threading.fdepl.in
    "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_threading.fdepl" @ONLY)

file(GLOB FDEPL_FILES "fidl/*.fdepl")
list(REMOVE_ITEM FDEPL_FILES "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_deployment.fdepl")
message("FDEPL_FILES: ${FDEPL_FILES}")
execute_process(
    COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} -nv --dest ${COMMONAPI_SRC_GEN_DEST} ${FDEPL_FILES}
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
# call the generator with disabled validation for the ti_dataypes_deployment.fdepl
execute_process(
    COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} --no-val --dest ${COMMONAPI_SRC_GEN_DEST} "${CMAKE_CURRENT_SOURCE_DIR}/fidl/ti_datatypes_deployment.fdepl"
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
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DBOOST_LOG_DYN_LINK -DUSE_VSOMEIP_STATISTICS -D_CRT_SECURE_NO_WARNINGS /EHsc -DCOMMONAPI_INTERNAL_COMPILATION /wd\\\"4503\\\"")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DBOOST_LOG_DYN_LINK -DUSE_VSOMEIP_STATISTICS -D_CRT_SECURE_NO_WARNINGS -DCOMMONAPI_INTERNAL_COMPILATION /wd\\\"4503\\\"")
else()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D${OS} -DUSE_VSOMEIP_STATISTICS -DBOOST_LOG_DYN_LINK -pthread -g -std=c++0x -Wall -Wextra -Wformat -Wformat-security -Wconversion -fexceptions -fstrict-aliasing -fstack-protector -fasynchronous-unwind-tables -fno-omit-frame-pointer -D_GLIBCXX_USE_NANOSLEEP")
endif()

message("Compiler options: ${CMAKE_CXX_FLAGS}")

include_directories(
    src
    ${COMMONAPI_SRC_GEN_DEST}
    ${COMMONAPI_INCLUDE_DIRS}
    ${VSOMEIP3_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
)

if (MSVC)
set (DERIVED_TYPE_SRC "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/derived/TestInterface.cpp")
set (POLYMORPHIC_TYPE_SRC "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/advanced/polymorph/TestInterface.cpp")
endif ()

# source files
file(GLOB GLUE_SRCS
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/communication/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/advanced/bselective/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/advanced/managed/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/advanced/extended/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/advanced/polymorph/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/primitive/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/advanced/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/combined/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/deployment/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/datatypes/derived/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/performance/primitive/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/performance/complex/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/runtime/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/threading/*SomeIP*.cpp"
    "${COMMONAPI_SRC_GEN_DEST}/v1/commonapi/stability/sp/*SomeIP*.cpp"
    ${DERIVED_TYPE_SRC}
    ${POLYMORPHIC_TYPE_SRC}
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
