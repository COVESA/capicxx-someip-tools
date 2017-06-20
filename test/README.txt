This file contains information for executing the CommonAPI-SomeIP unit tests.

Required environment variables:
-------------------------------

TO BE ADDED


Building and executing the tests:
----------------------------------
You need:
1) The CommonAPI library
2) The CommonAPI-SomeIP library
3) The generator tool for CommonAPI. The cmake option -DCOMMONAPI_TOOL_GENERATOR needs to point to the executable.
4) The generator tool for CommonAPI-SomeIP. The cmake option -DCOMMONAPI_SOMEIP_TOOL_GENERATOR needs to point to the executable.
5) Google test (GTEST) framework. You need to have the enviroment variable GTEST_ROOT point to your installed framework.
6) GLIB.

Steps for building:

export GTEST_ROOT=$YOUR_PATH_HERE/gtest-1.7.0/

rm -rf build
rm -rf src-gen
mkdir build
cd build
cmake \
-DCommonAPI_DIR=$(readlink -f ../../../ascgit017.CommonAPI/build) \
-DCommonAPI-SomeIP_DIR=$(readlink -f ../../../ascgit017.CommonAPI-SomeIP/build) \
-DCOMMONAPI_TOOL_GENERATOR=$(readlink -f ../../../ascgit017.CommonAPI-Tools/org.genivi.commonapi.core.cli.product/target/products/org.genivi.commonapi.core.cli.product/linux/gtk/x86_64/commonapi-generator-linux-x86_64) \
-DCOMMONAPI_SOMEIP_TOOL_GENERATOR=$(readlink -f ../../org.genivi.commonapi.someip.cli.product/target/products/org.genivi.commonapi.someip.cli.product/linux/gtk/x86_64/commonapi-someip-generator-linux-x86_64) \
..

make
ctest -V
