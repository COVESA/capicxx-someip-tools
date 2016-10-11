cmake_minimum_required (VERSION 2.8)
project (CommonAPI-SomeIP-Examples)
set (CMAKE_VERBOSE_MAKEFILE off)
#set (CMAKE_CXX_FLAGS "-pthread -g -std=c++0x -O0")

# Package config module not found message macro
macro (pkg_config_module_not_found_message PKG_CONFIG_MODULE)
    message (FATAL_ERROR "pkg-config could not find the required module ${PKG_CONFIG_MODULE}!"
      " Please adjust your PKG_CONFIG_PATH environment variable accordingly.")
endmacro ()

# OS
if (${CMAKE_SYSTEM_NAME} MATCHES "Linux")
    set (OS "LINUX")
    set (DL_LIBRARY "dl")
endif (${CMAKE_SYSTEM_NAME} MATCHES "Linux")

if (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")
    set (OS "FREEBSD")
    set(DL_LIBRARY "")
endif (${CMAKE_SYSTEM_NAME} MATCHES "FreeBSD")

set (CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -D${OS} -DUSE_VSOMEIP_STATISTICS -DBOOST_LOG_DYN_LINK -D_GLIBCXX_USE_NANOSLEEP -pthread -g -std=c++0x -O0 -Wno-deprecated-register")

###################################################################################################

#function (echo_all_cmake_variable_values)
#    message (STATUS "")
#    get_cmake_property (vs VARIABLES)
#    foreach (v ${vs})
#        message (STATUS "${v}='${${v}}'")
#    endforeach (v)
#    message (STATUS "")
#endfunction ()
#echo_all_cmake_variable_values ()

###################################################################################################

# Boost
find_package( Boost 1.54 COMPONENTS system thread log REQUIRED )
include_directories( ${Boost_INCLUDE_DIR} )

# Check for pkg-config availability
find_package(PkgConfig REQUIRED)
if (NOT PKG_CONFIG_FOUND)
    message (FATAL_ERROR "\"pkg-config\" is required, but was not found!")
endif ()

if ("${USE_INSTALLED_COMMONAPI}" STREQUAL "ON")
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_CMAKE_PACKAGE_REGISTRY)
else()
    FIND_PACKAGE(CommonAPI REQUIRED CONFIG NO_SYSTEM_ENVIRONMENT_PATH NO_CMAKE_SYSTEM_PATH)
endif()

message("CommonAPI_CONSIDERED_CONFIGS: ${CommonAPI_CONSIDERED_CONFIGS}")
message("COMMONAPI_INCLUDE_DIRS: ${COMMONAPI_INCLUDE_DIRS}")

find_package (CommonAPI-SomeIP 3.1.8 REQUIRED)
find_package (vsomeip 2.2.0 REQUIRED)

include_directories (
    ${COMMONAPI_INCLUDE_DIRS}
    ${COMMONAPI_SOMEIP_INCLUDE_DIRS}
    ${VSOMEIP_INCLUDE_DIRS}
    ${CMAKE_CURRENT_SOURCE_DIR}/src-gen
)

link_directories (
    ${COMMONAPI_PREFIX}/.libs
    ${COMMONAPI_SOMEIP_CMAKE_DIR}/build
)

# CommonAPI-SomeIP
add_library (someip-example-someip SHARED
    src-gen/v1/commonapi/someip/heartbeatSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/heartbeatSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/mathSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/mathSomeIPStubAdapter.cpp
)
target_link_libraries(someip-example-someip
    CommonAPI-SomeIP
)

add_library (someip-attribute-example-someip SHARED
    src-gen/v1/commonapi/someip/attrSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/attrSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/attrSomeIPDeployment.cpp
)
target_link_libraries(someip-attribute-example-someip
    CommonAPI-SomeIP
)

add_library (someip-attributeanonymtc-example-someip SHARED
    src-gen/v1/commonapi/someip/attranonymtcSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/attranonymtcSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/attranonymtcSomeIPDeployment.cpp
    src-gen/v2/commonapi/someip/__Anonymous__SomeIPDeployment.cpp
)
target_link_libraries(someip-attributeanonymtc-example-someip
    CommonAPI-SomeIP
)

add_library (someip-attributenamedtc-example-someip SHARED
    src-gen/v1/commonapi/someip/attrnamedtcSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/attrnamedtcSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/attrnamedtcSomeIPDeployment.cpp
    src-gen/v2/commonapi/someip/myTypeCollectionSomeIPDeployment.cpp
)
target_link_libraries(someip-attributenamedtc-example-someip
    CommonAPI-SomeIP
)

add_library (someip-math-example-someip SHARED
    src-gen/v1/commonapi/someip/mathSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/mathSomeIPStubAdapter.cpp
)
target_link_libraries(someip-math-example-someip
        CommonAPI-SomeIP
)

add_library (someip-serialization-example-someip SHARED
    src-gen/v1/commonapi/serialization/SampleSomeIPProxy.cpp
    src-gen/v1/commonapi/serialization/SampleSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/serialization/SampleSomeIPDeployment.cpp
)
target_link_libraries(someip-serialization-example-someip
        CommonAPI-SomeIP
)

add_library (someip-map-example-someip SHARED
    src-gen/v1/commonapi/someip/MapSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/MapSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/MapSomeIPDeployment.cpp
)
target_link_libraries(someip-map-example-someip
        CommonAPI-SomeIP
)

add_library (someip-methodSample-example-someip SHARED
    src-gen/v1/commonapi/someip/methodSampleSomeIPProxy.cpp
    src-gen/v1/commonapi/someip/methodSampleSomeIPStubAdapter.cpp
    src-gen/v1/commonapi/someip/methodSampleSomeIPDeployment.cpp
)
target_link_libraries(someip-methodSample-example-someip
        CommonAPI-SomeIP
)

# Executables
add_executable (someip-example-client
    src/client.cpp
)
target_link_libraries (
    someip-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-attribute-example-client
    src/attrClient.cpp
)
target_link_libraries (
    someip-attribute-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-attributeanonymtc-example-client
    src/attranonymtcClient.cpp
)
target_link_libraries (
    someip-attributeanonymtc-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-attributenamedtc-example-client
    src/attrnamedtcClient.cpp
)
target_link_libraries (
    someip-attributenamedtc-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-math-example-client-1
    src/mathClient1.cpp
)
target_link_libraries (
    someip-math-example-client-1
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-math-example-client-2
    src/mathClient2.cpp
)
target_link_libraries (
    someip-math-example-client-2
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-serialization-example-client
    src/serializationClient.cpp
)
target_link_libraries (
    someip-serialization-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-map-example-client
    src/mapClient.cpp
)
target_link_libraries (
    someip-map-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-methodSample-example-client
    src/methodSampleClient.cpp
)
target_link_libraries (
    someip-methodSample-example-client
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-example-service
    src/service.cpp
    src/heartbeatStubImpl.cpp
    src/mathStubImpl.cpp
    src-gen/v1/commonapi/someip/heartbeatStubDefault.cpp
    src-gen/v1/commonapi/someip/mathStubDefault.cpp
)
target_link_libraries (
    someip-example-service
    CommonAPI
    ${DL_LIBRARY}
)
 
add_executable (someip-attribute-example-service
    src/attrService.cpp
    src/attrStubImpl.cpp
    src-gen/v1/commonapi/someip/attrStubDefault.cpp
)
target_link_libraries (
    someip-attribute-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-attributeanonymtc-example-service
    src/attranonymtcService.cpp
    src/attranonymtcStubImpl.cpp
    src-gen/v1/commonapi/someip/attranonymtcStubDefault.cpp
)
target_link_libraries (
    someip-attributeanonymtc-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-attributenamedtc-example-service
    src/attrnamedtcService.cpp
    src/attrnamedtcStubImpl.cpp
    src-gen/v1/commonapi/someip/attrnamedtcStubDefault.cpp
)
target_link_libraries (
    someip-attributenamedtc-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-math-example-service
    src/mathService.cpp
    src/mathStubImpl.cpp
    src-gen/v1/commonapi/someip/mathStubDefault.cpp
)
target_link_libraries (
    someip-math-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-serialization-example-service
    src/serializationService.cpp
    src/serializationStubImpl.cpp
    src-gen/v1/commonapi/serialization/SampleStubDefault.cpp
)
target_link_libraries (
    someip-serialization-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-map-example-service
    src/mapService.cpp
    src/mapStubImpl.cpp
    src-gen/v1/commonapi/someip/MapStubDefault.cpp
)
target_link_libraries (
    someip-map-example-service
    CommonAPI
    ${DL_LIBRARY}
)

add_executable (someip-methodSample-example-service
    src/methodSampleService.cpp
    src/methodSampleStubImpl.cpp
    src-gen/v1/commonapi/someip/methodSampleStubDefault.cpp
)
target_link_libraries (
    someip-methodSample-example-service
    CommonAPI
    ${DL_LIBRARY}
)
