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

# Boost
find_package( Boost 1.54 COMPONENTS system thread log REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

if(Boost_FOUND)
  if(Boost_LIBRARY_DIR)
    MESSAGE( STATUS "Boost_LIBRARY_DIR not empty using it: ${Boost_LIBRARY_DIR}" )
  else()
    if(BOOST_LIBRARYDIR)
      MESSAGE( STATUS "Boost_LIBRARY_DIR empty but BOOST_LIBRARYDIR is set setting Boost_LIBRARY_DIR to: ${BOOST_LIBRARYDIR}" )
      set(Boost_LIBRARY_DIR ${BOOST_LIBRARYDIR})
    endif()
  endif()
else()
  MESSAGE( STATUS "Boost was not found!")
endif()

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
    ${COMMONAPI_INCLUDE_DIRS}
    ${SOMEIP_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
    ${GLIB_INCLUDE_DIRS}
    ${gtest_SOURCE_DIR}/include
    ${VSOMEIP3_INCLUDE_DIRS}
)

if ("${USE_INSTALLED_SOMEIP}" STREQUAL "OFF")
    link_directories(
        ${SOMEIP_INCLUDE_DIRS}/SOMEIP/.libs
    )
endif()


##############################################################################
# generate code from fidl

SET(TYPE_COLLECTION_DEPL_PREFIX "interface commonapi.someip.deploymenttest.TestInterface")
SET(FIDL_FILE_NAME "./deployment_test_ow.fidl")
SET(TYPE_COLLECTION_PREFIX "")
SET(TYPE_COLLECTION_BLOCK "")
SET(TYPE_COLLECTION_DEPL_BLOCK "")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/deployment_test_ow.fdepl.in
    "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/deployment_test.fidl.in
    "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow.fidl" @ONLY)

execute_process(COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} -dest ${COMMONAPI_SRC_GEN_DEST}/ow/someip "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow.fdepl"
                        WORKING_DIRECTORY ${COMMONAPI_SRC_GEN_DEST}/fidl
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest ${COMMONAPI_SRC_GEN_DEST}/ow/core "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow.fdepl"
                        WORKING_DIRECTORY ${COMMONAPI_SRC_GEN_DEST}/fidl
                        )

SET(TYPE_COLLECTION_DEPL_PREFIX "typeCollection commonapi.someip.deploymenttest.TC")
SET(FIDL_FILE_NAME "./deployment_test_ow_tc.fidl")
SET(TYPE_COLLECTION_PREFIX "TC.")
SET(TYPE_COLLECTION_BLOCK "}\ntypeCollection TC {\n  version {major 1 minor 0 }\n")
SET(TYPE_COLLECTION_DEPL_BLOCK "}\ndefine org.genivi.commonapi.someip.deployment for typeCollection commonapi.someip.deploymenttest.TC {\n")

configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/deployment_test_ow.fdepl.in
    "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow_tc.fdepl" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/fidl/conf/deployment_test.fidl.in
    "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow_tc.fidl" @ONLY)

execute_process(COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} -dest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow_tc.fdepl"
                        WORKING_DIRECTORY ${COMMONAPI_SRC_GEN_DEST}/fidl
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/core "${COMMONAPI_SRC_GEN_DEST}/fidl/deployment_test_ow_tc.fdepl"
                        WORKING_DIRECTORY ${COMMONAPI_SRC_GEN_DEST}/fidl
                        )
##############################################################################
# Add code from issue GLIPCI-2226 to see that it really compiles
##############################################################################
execute_process(COMMAND ${COMMONAPI_SOMEIP_TOOL_GENERATOR} -dest ${COMMONAPI_SRC_GEN_DEST}/ow/someip "${CMAKE_CURRENT_SOURCE_DIR}/fidl/de.bmw.infrastructure.testability.fdepl"
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/fidl
                        )
execute_process(COMMAND ${COMMONAPI_TOOL_GENERATOR} -sk Default -dest ${COMMONAPI_SRC_GEN_DEST}/ow/core "${CMAKE_CURRENT_SOURCE_DIR}/fidl/de.bmw.infrastructure.testability.fdepl"
                        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}/fidl
                        )
set(GLIPCI-2226_Sources
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v1/de/bmw/infrastructure/testability/EnhancedTestabilityServiceTPSomeIPStubAdapter.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v1/de/bmw/infrastructure/testability/EnhancedTestabilityServiceTPSomeIPDeployment.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v1/de/bmw/infrastructure/testability/EnhancedTestabilityServiceTPSomeIPProxy.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v2/de/bmw/infrastructure/testability/EnhancedTestabilityServiceHigh2SomeIPProxy.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v2/de/bmw/infrastructure/testability/EnhancedTestabilityServiceHigh2SomeIPDeployment.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/v2/de/bmw/infrastructure/testability/EnhancedTestabilityServiceHigh2SomeIPStubAdapter.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/de/bmw/environmentalmodel/common/CommonSomeIPDeployment.cpp
    ${COMMONAPI_SRC_GEN_DEST}/ow/someip/de/bmw/infrastructure/testabilitytypes/TestabilityTypesSomeIPDeployment.cpp)

##############################################################################
set(VERSION "v1")

set(TestInterfaceSources ${COMMONAPI_SRC_GEN_DEST}/src/stub/DeploymentTestStub.cpp)

set(TestInterfaceSomeIPSources ${TestInterfaceSources}
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPProxy.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPStubAdapter.cpp)

set(TestInterfaceTCSources ${COMMONAPI_SRC_GEN_DEST}/tc/src/stub/DeploymentTestStub.cpp)


set(TestInterfaceTCSomeIPSources ${TestInterfaceTCSources}
                             ${COMMONAPI_SRC_GEN_DEST}/tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPProxy.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/tc/someip/${VERSION}/commonapi/someip/deploymenttest/TCSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPStubAdapter.cpp)

set(TestInterfaceOWSources ${COMMONAPI_SRC_GEN_DEST}/ow/src/stub/DeploymentTestStub.cpp)

set(TestInterfaceOWSomeIPSources ${TestInterfaceOWSources}
                             ${COMMONAPI_SRC_GEN_DEST}/ow/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/ow/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPProxy.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/ow/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPStubAdapter.cpp)

set(TestInterfaceOWTCSources ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/stub/DeploymentTestStub.cpp)


set(TestInterfaceOWTCSomeIPSources ${TestInterfaceOWTCSources}
                             ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPProxy.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip/${VERSION}/commonapi/someip/deploymenttest/TCSomeIPDeployment.cpp
                             ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip/${VERSION}/commonapi/someip/deploymenttest/TestInterfaceSomeIPStubAdapter.cpp)


set(TEST_LINK_LIBRARIES -Wl,--no-as-needed CommonAPI-SomeIP -Wl,--as-needed CommonAPI ${SOMEIP_LDFLAGS} ${DL_LIBRARY} gtest ${PTHREAD_LIBRARY})

##############################################################################
# configure & copy source files
##############################################################################
SET(TYPE_COLLECTION_BASE_NAME "TestInterface")
SET(TYPE_COLLECTION_FULL_NAME "v1_0::commonapi::someip::deploymenttest::TestInterface")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/stub/DeploymentTestStub.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/stub/DeploymentTestStub.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/stub/DeploymentTestStub.h
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/stub/DeploymentTestStub.h" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPArrayDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPArrayDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPByteBufferDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPByteBufferDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPEnumDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPEnumDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPIntegerDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPIntegerDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPMapDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPMapDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPStringDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPStringDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPStructDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPStructDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPUnionDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPUnionDeploymentTest.cpp" @ONLY)

SET(TYPE_COLLECTION_BASE_NAME "TC")
SET(TYPE_COLLECTION_FULL_NAME "v1_0::commonapi::someip::deploymenttest::TC")
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/stub/DeploymentTestStub.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/stub/DeploymentTestStub.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/stub/DeploymentTestStub.h
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/stub/DeploymentTestStub.h" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPArrayDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPArrayDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPByteBufferDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPByteBufferDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPEnumDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPEnumDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPIntegerDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPIntegerDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPMapDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPMapDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPStringDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPStringDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPStructDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPStructDeploymentTest.cpp" @ONLY)
configure_file(${CMAKE_CURRENT_SOURCE_DIR}/src/SomeIPUnionDeploymentTest.cpp
    "${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPUnionDeploymentTest.cpp" @ONLY)

##############################################################################
# SomeIPIntegerDeploymentTest
##############################################################################
set(TEST_INCLUDE_OW_DIRS ${COMMONAPI_SRC_GEN_DEST}/ow/src ${COMMONAPI_SRC_GEN_DEST}/ow/src/stub ${COMMONAPI_SRC_GEN_DEST}/ow/someip ${COMMONAPI_SRC_GEN_DEST}/ow/core)
set(TEST_INCLUDE_OWTC_DIRS ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/stub ${COMMONAPI_SRC_GEN_DEST}/ow_tc/someip ${COMMONAPI_SRC_GEN_DEST}/ow_tc/core)

add_executable(SomeIPIntegerDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPIntegerDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources} ${GLIPCI-2226_Sources})
target_link_libraries(SomeIPIntegerDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPIntegerDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPIntegerDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPIntegerDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPIntegerDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPIntegerDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})
##############################################################################
# SomeIPArrayDeploymentTest
##############################################################################

add_executable(SomeIPArrayDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPArrayDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPArrayDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPArrayDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPArrayDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPArrayDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPArrayDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPArrayDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})

##############################################################################
# SomeIPByteBufferDeploymentTest
##############################################################################

add_executable(SomeIPByteBufferDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPByteBufferDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPByteBufferDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPByteBufferDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPByteBufferDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPByteBufferDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPByteBufferDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPByteBufferDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})

##############################################################################
# SomeIPMapDeploymentTest
##############################################################################

add_executable(SomeIPMapDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPMapDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPMapDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPMapDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPMapDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPMapDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPMapDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPMapDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})
##############################################################################
# SomeIPEnumDeploymentTest
##############################################################################

add_executable(SomeIPEnumDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPEnumDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPEnumDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPEnumDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPEnumDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPEnumDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPEnumDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPEnumDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})

##############################################################################
# SomeIPUnionDeploymentTest
##############################################################################

add_executable(SomeIPUnionDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPUnionDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPUnionDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPUnionDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPUnionDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPUnionDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPUnionDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPUnionDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})

##############################################################################
# SomeIPStructDeploymentTest
##############################################################################

add_executable(SomeIPStructDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPStructDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPStructDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPStructDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPStructDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPStructDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPStructDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPStructDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})

##############################################################################
# SomeIPStringDeploymentTest
##############################################################################

add_executable(SomeIPStringDeploymentOWTest ${COMMONAPI_SRC_GEN_DEST}/ow/src/SomeIPStringDeploymentTest.cpp
                               ${TestInterfaceOWSomeIPSources})
target_link_libraries(SomeIPStringDeploymentOWTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPStringDeploymentOWTest PRIVATE ${TEST_INCLUDE_OW_DIRS})

add_executable(SomeIPStringDeploymentOWTCTest ${COMMONAPI_SRC_GEN_DEST}/ow_tc/src/SomeIPStringDeploymentTest.cpp
                               ${TestInterfaceOWTCSomeIPSources})
target_link_libraries(SomeIPStringDeploymentOWTCTest ${TEST_LINK_LIBRARIES})
target_include_directories(SomeIPStringDeploymentOWTCTest PRIVATE ${TEST_INCLUDE_OWTC_DIRS})
##############################################################################
# Add for every test a dependency to gtest
##############################################################################

add_dependencies(SomeIPIntegerDeploymentOWTest gtest)
add_dependencies(SomeIPArrayDeploymentOWTest gtest)
add_dependencies(SomeIPEnumDeploymentOWTest gtest)
add_dependencies(SomeIPUnionDeploymentOWTest gtest)
add_dependencies(SomeIPStructDeploymentOWTest gtest)
add_dependencies(SomeIPStringDeploymentOWTest gtest)
add_dependencies(SomeIPMapDeploymentOWTest gtest)
add_dependencies(SomeIPByteBufferDeploymentOWTest gtest)

add_dependencies(SomeIPIntegerDeploymentOWTCTest gtest)
add_dependencies(SomeIPArrayDeploymentOWTCTest gtest)
add_dependencies(SomeIPEnumDeploymentOWTCTest gtest)
add_dependencies(SomeIPUnionDeploymentOWTCTest gtest)
add_dependencies(SomeIPStructDeploymentOWTCTest gtest)
add_dependencies(SomeIPStringDeploymentOWTCTest gtest)
add_dependencies(SomeIPMapDeploymentOWTCTest gtest)
add_dependencies(SomeIPByteBufferDeploymentOWTCTest gtest)

##############################################################################
# Add tests to the target build_tests
##############################################################################

add_dependencies(build_tests SomeIPIntegerDeploymentOWTest)
add_dependencies(build_tests SomeIPArrayDeploymentOWTest)
add_dependencies(build_tests SomeIPEnumDeploymentOWTest)
add_dependencies(build_tests SomeIPUnionDeploymentOWTest)
add_dependencies(build_tests SomeIPStructDeploymentOWTest)
add_dependencies(build_tests SomeIPStringDeploymentOWTest)
add_dependencies(build_tests SomeIPMapDeploymentOWTest)
add_dependencies(build_tests SomeIPByteBufferDeploymentOWTest)

add_dependencies(build_tests SomeIPIntegerDeploymentOWTCTest)
add_dependencies(build_tests SomeIPArrayDeploymentOWTCTest)
add_dependencies(build_tests SomeIPEnumDeploymentOWTCTest)
add_dependencies(build_tests SomeIPUnionDeploymentOWTCTest)
add_dependencies(build_tests SomeIPStructDeploymentOWTCTest)
add_dependencies(build_tests SomeIPStringDeploymentOWTCTest)
add_dependencies(build_tests SomeIPMapDeploymentOWTCTest)
add_dependencies(build_tests SomeIPByteBufferDeploymentOWTCTest)
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

add_test(NAME SomeIPIntegerDeploymentOWTest COMMAND SomeIPIntegerDeploymentOWTest)
set_property(TEST SomeIPIntegerDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPArrayDeploymentOWTest COMMAND SomeIPArrayDeploymentOWTest)
set_property(TEST SomeIPArrayDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPByteBufferDeploymentOWTest COMMAND SomeIPByteBufferDeploymentOWTest)
set_property(TEST SomeIPByteBufferDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPMapDeploymentOWTest COMMAND SomeIPMapDeploymentOWTest)
set_property(TEST SomeIPMapDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPEnumDeploymentOWTest COMMAND SomeIPEnumDeploymentOWTest)
set_property(TEST SomeIPEnumDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPUnionDeploymentOWTest COMMAND SomeIPUnionDeploymentOWTest)
set_property(TEST SomeIPUnionDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStructDeploymentOWTest COMMAND SomeIPStructDeploymentOWTest)
set_property(TEST SomeIPStructDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStringDeploymentOWTest COMMAND SomeIPStringDeploymentOWTest)
set_property(TEST SomeIPStringDeploymentOWTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPIntegerDeploymentOWTCTest COMMAND SomeIPIntegerDeploymentOWTCTest)
set_property(TEST SomeIPIntegerDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPArrayDeploymentOWTCTest COMMAND SomeIPArrayDeploymentOWTCTest)
set_property(TEST SomeIPArrayDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPByteBufferDeploymentOWTCTest COMMAND SomeIPByteBufferDeploymentOWTCTest)
set_property(TEST SomeIPByteBufferDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPMapDeploymentOWTCTest COMMAND SomeIPMapDeploymentOWTCTest)
set_property(TEST SomeIPMapDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPEnumDeploymentOWTCTest COMMAND SomeIPEnumDeploymentOWTCTest)
set_property(TEST SomeIPEnumDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPUnionDeploymentOWTCTest COMMAND SomeIPUnionDeploymentOWTCTest)
set_property(TEST SomeIPUnionDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStructDeploymentOWTCTest COMMAND SomeIPStructDeploymentOWTCTest)
set_property(TEST SomeIPStructDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})

add_test(NAME SomeIPStringDeploymentOWTCTest COMMAND SomeIPStringDeploymentOWTCTest)
set_property(TEST SomeIPStringDeploymentOWTCTest APPEND PROPERTY ENVIRONMENT ${SOMEIP_TEST_ENVIRONMENT})
