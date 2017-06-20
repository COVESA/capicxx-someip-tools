# Copyright (C) 2013-2017 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at http://mozilla.org/MPL/2.0/.

cmake_minimum_required (VERSION 2.8.1)

PROJECT(commonapi_someip_depl_test)

message("Project name: ${PROJECT_NAME}")

SET( ${PROJECT_NAME}_MAJOR_VERSION 3 )
SET( ${PROJECT_NAME}_MINOR_VERSION 1 )
SET( ${PROJECT_NAME}_PATCH_LEVEL 11 )
##############################################################################

# create the commandline variables:
OPTION(USE_INSTALLED_COMMONAPI "Set to OFF to use the local (build tree) version of CommonAPI" ON)
message("USE_INSTALLED_COMMONAPI is set to value: ${USE_INSTALLED_COMMONAPI}")

OPTION(USE_INSTALLED_GTEST "Set to ON to use an installed version of GTEST" OFF)
message("USE_INSTALLED_GTEST is set to value: ${USE_INSTALLED_GTEST}")

OPTION(USE_INSTALLED_SOMEIP "Set to OFF to use the local (build tree) version of SOMEIP" ON)
message(STATUS "USE_INSTALLED_SOMEIP is set to value: ${USE_INSTALLED_SOMEIP}")

if(NOT CMAKE_BUILD_TYPE)
   set(CMAKE_BUILD_TYPE "Debug" CACHE STRING
       "Choose the type of build, options are: Debug Release." FORCE)
endif(NOT CMAKE_BUILD_TYPE)

SET(COMMONAPI_SRC_GEN_DEST "${COMMONAPI_SRC_GEN_DEST}" CACHE STRING "Path to the destination directory of the generated sources")
message("The path to the destination directory of the generated sources is set to: ${COMMONAPI_SRC_GEN_DEST}")

if("${COMMONAPI_SOMEIP_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi_SOMEIP_generator needs to be specified! Use '-DCOMMONAPI_SOMEIP_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_SOMEIP_TOOL_GENERATOR specified: ${COMMONAPI_SOMEIP_TOOL_GENERATOR}")
endif()

if("${COMMONAPI_TOOL_GENERATOR}" STREQUAL "na")
    message(FATAL_ERROR "The file path for the commonapi_SOMEIP_generator needs to be specified! Use '-DCOMMONAPI_TOOL_GENERATOR' to do so.")
    return()
else()
    message("COMMONAPI_TOOL_GENERATOR specified: ${COMMONAPI_TOOL_GENERATOR}")
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

FIND_PACKAGE(PkgConfig)

# find commonapi
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

# Boost
find_package( Boost 1.54 COMPONENTS system thread log REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

link_directories(
    ${Boost_LIBRARY_DIR}
)

##############################################################################
# google test

#check for set environment variable
if(DEFINED ENV{GTEST_ROOT})
message("GTEST_ROOT is set. GTEST_ROOT = $ENV{GTEST_ROOT}")
else()
    message("GTEST_ROOT is not defined. For building the tests environment variable
             GTEST_ROOT have to be defined. Tests can not be built.")
    # early exit
    return()  # test can not be build -> make check is not available
endif()

if ("${USE_INSTALLED_GTEST}" STREQUAL "ON")
    find_package(GTest REQUIRED)
else()
    # build google test as static library (always) -> therefore deactivate BUILD_SHARED_LIBS in case it is active
    set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 0)
    if ("${BUILD_SHARED_LIBS}" STREQUAL "ON")
       set(BUILD_SHARED_LIBS OFF)
       set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 1)
    endif()

    # ...but visual studio needs a shared CRT for gtest, otherwise the linker won't work correctly with the testcases.
    if (MSVC)
       set( gtest_force_shared_crt ON CACHE BOOL "Always use msvcrt.dll" )
    endif()

    add_subdirectory($ENV{GTEST_ROOT} ${CMAKE_CURRENT_BINARY_DIR}/gtest EXCLUDE_FROM_ALL)
    if ("${BUILD_SHARED_LIBS_AUTOMATIC_OFF}" STREQUAL "1")
        set(BUILD_SHARED_LIBS ON)
        set(BUILD_SHARED_LIBS_AUTOMATIC_OFF 0)
    endif()

    set(GTEST_INCLUDE_DIRS  ${gtest_SOURCE_DIR}/include)
    set(GTEST_LIBRARIES gtest)
endif()

# Enable gtest
enable_testing()

add_custom_target(build_tests)

set(CMAKE_CTEST_COMMAND ctest -V)
add_custom_target(check COMMAND ${CMAKE_CTEST_COMMAND})

add_dependencies(check build_tests)

if (MSVC)
# Visual C++ is not always sure whether he is really C++
set(CMAKE_C_FLAGS "${CMAKE_C_FLAGS} -DCOMMONAPI_INTERNAL_COMPILATION /EHsc /wd\\\"4503\\\"")
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -DCOMMONAPI_INTERNAL_COMPILATION /wd\\\"4503\\\"")
set(USE_RT "")
else()
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -std=c++11 -pthread -Wall -Wextra -Wformat -Wformat-security -Wconversion -fexceptions -fstrict-aliasing -fstack-protector -fasynchronous-unwind-tables -fno-omit-frame-pointer -D_GLIBCXX_USE_NANOSLEEP")
set(USE_RT "rt")
endif()

message("Compiler options: ${CMAKE_CXX_FLAGS}")

include_directories(
    src
    src/stub
    ${COMMONAPI_SRC_GEN_DEST}/someip
    ${COMMONAPI_SRC_GEN_DEST}/core
    ${COMMONAPI_INCLUDE_DIRS}
    ${SOMEIP_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
    ${gtest_SOURCE_DIR}/include
    ${VSOMEIP_INCLUDE_DIRS}
)

if ("${USE_INSTALLED_SOMEIP}" STREQUAL "OFF")
    link_directories(
        ${SOMEIP_INCLUDE_DIRS}/SOMEIP/.libs
    )
endif()


##############################################################################
# generate code from fidl
file(GLOB FDEPL_FILES "fidl/*.fdepl")
file(GLOB FIDL_FILES "fidl/*.fidl")

execute_process(COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} -dest ${COMMONAPI_SRC_GEN_DEST}/someip ${FDEPL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest ${COMMONAPI_SRC_GEN_DEST}/core ${FDEPL_FILES}
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
                        )
##############################################################################

set(VERSION "v1")

set(TestInterfaceSources ${COMMONAPI_SRC_GEN_DEST}/core/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceStubDefault.cpp
                         src/stub/DeploymentTestStub.cpp)

set(TestInterfaceSomeIPSources ${TestInterfaceSources}
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPProxy.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPStubAdapter.cpp)

set(TEST_LINK_LIBRARIES -Wl,--no-as-needed CommonAPI-SomeIP -Wl,--as-needed CommonAPI ${SOMEIP_LDFLAGS} ${DL_LIBRARY} gtest ${PTHREAD_LIBRARY})


##############################################################################
# SomeIPIntegerDeploymentTest
##############################################################################

add_executable(SomeIPIntegerDeploymentTest src/SomeIPIntegerDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPIntegerDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPArrayDeploymentTest
##############################################################################

add_executable(SomeIPArrayDeploymentTest src/SomeIPArrayDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPArrayDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPByteBufferDeploymentTest
##############################################################################

add_executable(SomeIPByteBufferDeploymentTest src/SomeIPByteBufferDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPByteBufferDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPMapDeploymentTest
##############################################################################

add_executable(SomeIPMapDeploymentTest src/SomeIPMapDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPMapDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPEnumDeploymentTest
##############################################################################

add_executable(SomeIPEnumDeploymentTest src/SomeIPEnumDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPEnumDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPUnionDeploymentTest
##############################################################################

add_executable(SomeIPUnionDeploymentTest src/SomeIPUnionDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPUnionDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPStructDeploymentTest
##############################################################################

add_executable(SomeIPStructDeploymentTest src/SomeIPStructDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPStructDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# SomeIPStringDeploymentTest
##############################################################################

add_executable(SomeIPStringDeploymentTest src/SomeIPStringDeploymentTest.cpp
                               ${TestInterfaceSomeIPSources})
target_link_libraries(SomeIPStringDeploymentTest ${TEST_LINK_LIBRARIES})

##############################################################################
# Add for every test a dependency to gtest
##############################################################################

add_dependencies(SomeIPIntegerDeploymentTest gtest)
add_dependencies(SomeIPArrayDeploymentTest gtest)
add_dependencies(SomeIPEnumDeploymentTest gtest)
add_dependencies(SomeIPUnionDeploymentTest gtest)
add_dependencies(SomeIPStructDeploymentTest gtest)
add_dependencies(SomeIPStringDeploymentTest gtest)
add_dependencies(SomeIPMapDeploymentTest gtest)
add_dependencies(SomeIPByteBufferDeploymentTest gtest)

##############################################################################
# Add tests to the target build_tests
##############################################################################

add_dependencies(build_tests SomeIPIntegerDeploymentTest)
add_dependencies(build_tests SomeIPArrayDeploymentTest)
add_dependencies(build_tests SomeIPEnumDeploymentTest)
add_dependencies(build_tests SomeIPUnionDeploymentTest)
add_dependencies(build_tests SomeIPStructDeploymentTest)
add_dependencies(build_tests SomeIPStringDeploymentTest)
add_dependencies(build_tests SomeIPMapDeploymentTest)
add_dependencies(build_tests SomeIPByteBufferDeploymentTest)



##############################################################################
# configure configuration files
##############################################################################
get_filename_component(INI_FILE ${CMAKE_CURRENT_SOURCE_DIR}/commonapi4someip.ini ABSOLUTE)

set(SOMEIP_COMMONAPI_CONFIG "COMMONAPI_CONFIG=${INI_FILE}")
if ("${SOMEIP_VSOMEIP_JSON_FILE}" STREQUAL "")
    set(SOMEIP_VSOMEIP_JSON_FILE "../vsomeip.json")
endif()
set(VSOMEIP_CONFIGURATION "VSOMEIP_CONFIGURATION=${SOMEIP_VSOMEIP_JSON_FILE}")
set(SOMEIP_TEST_ENVIRONMENT
    ${SOMEIP_COMMONAPI_CONFIG}
    ${VSOMEIP_CONFIGURATION}
)

##############################################################################
# Add tests
##############################################################################

add_test(NAME SomeIPIntegerDeploymentTest COMMAND SomeIPIntegerDeploymentTest)
set_property(TEST SomeIPIntegerDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPArrayDeploymentTest COMMAND SomeIPArrayDeploymentTest)
set_property(TEST SomeIPArrayDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPByteBufferDeploymentTest COMMAND SomeIPByteBufferDeploymentTest)
set_property(TEST SomeIPByteBufferDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPMapDeploymentTest COMMAND SomeIPMapDeploymentTest)
set_property(TEST SomeIPMapDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPEnumDeploymentTest COMMAND SomeIPEnumDeploymentTest)
set_property(TEST SomeIPEnumDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPUnionDeploymentTest COMMAND SomeIPUnionDeploymentTest)
set_property(TEST SomeIPUnionDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStructDeploymentTest COMMAND SomeIPStructDeploymentTest)
set_property(TEST SomeIPStructDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStringDeploymentTest COMMAND SomeIPStringDeploymentTest)
set_property(TEST SomeIPStringDeploymentTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})
