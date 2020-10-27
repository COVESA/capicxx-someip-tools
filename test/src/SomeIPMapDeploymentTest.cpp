/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPMapDeploymentTest
*/

#include <functional>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <fstream>
#include <numeric>
#include <gtest/gtest.h>
#include "CommonAPI/CommonAPI.hpp"

#ifndef COMMONAPI_INTERNAL_COMPILATION
#define COMMONAPI_INTERNAL_COMPILATION
#endif
#include <CommonAPI/SomeIP/Address.hpp>
#include <CommonAPI/SomeIP/Message.hpp>
#include <CommonAPI/SomeIP/OutputStream.hpp>
#include <CommonAPI/SomeIP/InputStream.hpp>
#include <CommonAPI/SomeIP/Proxy.hpp>
#include <CommonAPI/SomeIP/Types.hpp>
#include "v1/commonapi/someip/deploymenttest/TestInterfaceProxy.hpp"
#include "DeploymentTestStub.h"

const std::string domain = "local";
const std::string testAddress = "commonapi.someip.deploymenttest.TestInterface";
const std::string connectionIdService = "service-sample";
const std::string connectionIdClient = "client-sample";

const int tasync = 10000;

class Environment: public ::testing::Environment {
public:
    virtual ~Environment() {
    }

    virtual void SetUp() {
    }

    virtual void TearDown() {
    }
};

class DeploymentTest: public ::testing::Test {
protected:
    void SetUp() {
        runtime_ = CommonAPI::Runtime::get();
        ASSERT_TRUE((bool)runtime_);

        testStub_ = std::make_shared<v1_0::commonapi::someip::deploymenttest::DeploymentTestStub>();
        serviceRegistered_ = runtime_->registerService(domain, testAddress, testStub_, connectionIdService);
        ASSERT_TRUE(serviceRegistered_);

        testProxy_ = runtime_->buildProxy<v1_0::commonapi::someip::deploymenttest::TestInterfaceProxy>(domain, testAddress, connectionIdClient);
        int i = 0;
        while(!testProxy_->isAvailable() && i++ < 100) {
            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
        ASSERT_TRUE(testProxy_->isAvailable());
    }

    void TearDown() {
        ASSERT_TRUE(runtime_->unregisterService(domain, v1_0::commonapi::someip::deploymenttest::DeploymentTestStub::StubInterface::getInterface(), testAddress));

        // wait that proxy is not available
        int counter = 0;  // counter for avoiding endless loop
        while ( testProxy_->isAvailable() && counter < 100 ) {
            std::this_thread::sleep_for(std::chrono::microseconds(tasync));
            counter++;
        }

        ASSERT_FALSE(testProxy_->isAvailable());
    }

    bool received_;
    bool serviceRegistered_;
    std::shared_ptr<CommonAPI::Runtime> runtime_;

    std::shared_ptr<v1_0::commonapi::someip::deploymenttest::TestInterfaceProxy<>> testProxy_;
    std::shared_ptr<v1_0::commonapi::someip::deploymenttest::DeploymentTestStub> testStub_;
};
/**
* @test Verify that the API for map deployments works
*/
TEST_F(DeploymentTest, MapWithDeployment) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed(nullptr, nullptr, 0, 4, 0);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    std::unordered_map<uint8_t, std::string> outMap = {
        {1, "one"},
        {2, "two"},
        {3, "three"},
        {4, "four"},
    };

    outStream.writeValue(outMap, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    std::unordered_map<uint8_t, std::string> inMap;
    inStream.readValue(inMap, &ed);

    EXPECT_EQ(outMap, inMap);
}
/**
* @test Try to stream maps that have a different number of elements that the deployment allows.
*/
TEST_F(DeploymentTest, MapWithWrongNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_0(nullptr, nullptr, 0, 4, 0);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_1(nullptr, nullptr, 3, 200, 1);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_2(nullptr, nullptr, 5, 2000, 2);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_4(nullptr, nullptr, 10, 200000, 4);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
            {3, "three"},
            {4, "four"},
            {5, "five"},
        };

        outStream.writeValue(outMap, &ed_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
            {3, "three"},
        };

        outStream.writeValue(outMap, &ed_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
        };

        outStream.writeValue(outMap, &ed_1);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 201; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_1);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
            {3, "three"},
            {4, "four"},
        };

        outStream.writeValue(outMap, &ed_2);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 2001; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_2);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 9; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_4);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 200001; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_4);
        EXPECT_TRUE(outStream.hasError());
    }
}
/**
* @test Try to stream maps that have a correct number of elements
*/
TEST_F(DeploymentTest, MapWithCorrectNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_0(nullptr, nullptr, 0, 5, 0);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_1(nullptr, nullptr, 3, 13, 1);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_2(nullptr, nullptr, 5, 1000, 2);
    CommonAPI::SomeIP::MapDeployment<CommonAPI::EmptyDeployment, CommonAPI::EmptyDeployment> ed_4(nullptr, nullptr, 10, 100000, 4);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
            {3, "three"},
            {4, "four"},
            {5, "five"},
        };

        outStream.writeValue(outMap, &ed_0);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<uint8_t, std::string> inMap;
        inStream.readValue(inMap, &ed_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<uint8_t, std::string> outMap = {
            {1, "one"},
            {2, "two"},
            {3, "three"},
        };

        outStream.writeValue(outMap, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<uint8_t, std::string> inMap;
        inStream.readValue(inMap, &ed_1);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 11; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_1);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 13; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_1);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 5; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 1000; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string>  inMap;
        inStream.readValue(inMap, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 222; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 10; i++) {
            outMap.insert(std::pair<int, std::string>(i, "walue"));
        }

        outStream.writeValue(outMap, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string>inMap;
        inStream.readValue(inMap, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 100000; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));;
        }

        outStream.writeValue(outMap, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::unordered_map<int, std::string> outMap ;
        for (int i = 0; i < 1000; i++) {
            outMap.insert(std::pair<int, std::string>(i, "value"));
        }

        outStream.writeValue(outMap, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::unordered_map<int, std::string> inMap;
        inStream.readValue(inMap, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inMap.size(), outMap.size());

        EXPECT_EQ(outMap, inMap);
    }
}
/**
* @test Use an attribute with map type, and pass a correct number of elements.
*/
TEST_F(DeploymentTest, MapAttributeWithCorrectNumberOfElements) {

    CommonAPI::CallStatus callStatus;
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 10; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v1"));
        }
        testProxy_->getAMapw0n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 20; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v2"));
        }

        testProxy_->getAMapw0n5x20Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;

        testProxy_->getAMapw1n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 1; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v4"));
        }

        testProxy_->getAMapw1n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 10; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v5"));;
        }

        testProxy_->getAMapw1n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 5; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v6"));
        }

        testProxy_->getAMapw1n5x50Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 15; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v7"));
        }

        testProxy_->getAMapw1n5x50Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 15; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v8"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 1000; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v9"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 1000; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v10"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 400; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v11"));
        }

        testProxy_->getAMapw4n400x200000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 20000; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v12"));
        }

        testProxy_->getAMapw4n400x200000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 200000; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v13"));
        }

        testProxy_->getAMapw4n400x200000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outMap, inMap);
    }
}
/**
* @test Use an attribute with map type, and try to pass an incorrect number of elements.
*/
TEST_F(DeploymentTest, MapAttributeWithWrongNumberOfElements) {

    CommonAPI::CallStatus callStatus;
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 9; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "vx1"));
        }
        testProxy_->getAMapw0n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 4; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "vx2"));
        }

        testProxy_->getAMapw0n5x20Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 21; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "q"));
        }

        testProxy_->getAMapw0n5x20Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 11; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "q"));
        }
        testProxy_->getAMapw1n0x10Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 4; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "four"));
        }

        testProxy_->getAMapw1n5x50Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 51; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, ""));
        }

        testProxy_->getAMapw1n5x50Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        // 10 values is within legal limits, but with a string this long,
        // the size of the map won't fit in one byte.
        for (uint32_t i = 0; i < 10; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "this_is_too_long"));
        }

        testProxy_->getAMapw1n5x50Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 14; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "zz"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 2001; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "qzz"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        // 1900 values is within legal limits, but with a string this long,
        // the size of the map won't fit in two bytes
        for (uint32_t i = 0; i < 1900; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "ThisStringIsWayTooLongToFitInTheData"));
        }

        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        testProxy_->getAMapw2n15x2000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 399; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "v1q3"));
        }

        testProxy_->getAMapw4n400x200000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::unordered_map<uint32_t, std::string> outMap ;
        std::unordered_map<uint32_t, std::string> inMap ;
        for (uint32_t i = 0; i < 200001; i++) {
            outMap.insert(std::pair<uint32_t, std::string>(i, "qq"));
        }

        testProxy_->getAMapw4n400x200000Attribute().setValue(outMap, callStatus, inMap);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Use a method with a map as an argument. for both input and output.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 300; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "400"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_io(outMap, callStatus, inMap);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(400UL, inMap.size());
}
/**
* @test Use a method with a map as an argument. for both input and output. Give wrong number of elements in the input value.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO_BadInput) {

    std::unordered_map<uint32_t, std::string> outMap;
    // 299 items is just too little. this should fail.
    for (uint32_t i = 1; i < 299; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "400"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_io(outMap, callStatus, inMap);

    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}
/**
* @test Use a method with a map as an argument. for both input and output. Give wrong number of elements in the output value.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO_BadOutput) {

    std::unordered_map<uint32_t, std::string> outMap;

    for (uint32_t i = 1; i < 300; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    // 399 is too few, so it will fail when the value is returned.
    outMap.insert(std::pair<uint32_t, std::string>(0, "399"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_io(outMap, callStatus, inMap);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}
/**
* @test Use a method with a map as an argument. for either input or output.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O) {

    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 20; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "40"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_i(outMap, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mMap_o(callStatus, inMap);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(40UL, inMap.size());
}
/**
* @test Use a method with a map as an input argument. Give wrong nummber of elements.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O_BadInput) {

    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 21; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "40"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_i(outMap, callStatus);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
}
/**
* @test Use a method with a map as an output argument. Give wrong nummber of elements.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O_BadOutput) {

    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 20; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "41"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_i(outMap, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mMap_o(callStatus, inMap);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}
/**
* @test Use a method with a map as an input and output argument. Give correct number of elements.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO_MinLength) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 5; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "6"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n5_io(outMap, callStatus, inMap);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(6UL, inMap.size());
}
/**
* @test Use a method with a map as an input and output argument. Give too few elements in the input.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO_MinLength_BadInput) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 4; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "6"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n5_io(outMap, callStatus, inMap);

    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
}
/**
* @test Use a method with a map as an input and output argument. Give too few elements in the output.
*/
TEST_F(DeploymentTest, MapMethodDeployment_IO_MinLength_BadOutput) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 5; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "5"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n5_io(outMap, callStatus, inMap);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}
/**
* @test Use a method with a map as either an input or output argument.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O_MinLength) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 6; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "7"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n6_i(outMap, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mMap_n7_o(callStatus, inMap);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(7UL, inMap.size());
}
/**
* @test Use a method with a map as an input argument. Give too few elements in the input.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O_MinLength_BadInput) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 5; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "7"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n6_i(outMap, callStatus);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
}
/**
* @test Use a method with a map as an output argument. Give too few elements in the output.
*/
TEST_F(DeploymentTest, MapMethodDeployment_I_O_MinLength_BadOutput) {
    std::unordered_map<uint32_t, std::string> outMap;
    for (uint32_t i = 1; i < 6; i++) {
        outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
    }
    // the item for key 0 gives the # of elements in the return map
    outMap.insert(std::pair<uint32_t, std::string>(0, "6"));

    std::unordered_map<uint32_t, std::string> inMap ;
    CommonAPI::CallStatus callStatus;
    testProxy_->mMap_n6_i(outMap, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mMap_n7_o(callStatus, inMap);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}

/**
* @test Use a broadcast with a map.
*/
TEST_F(DeploymentTest, MapBroadcastDeployment) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::unordered_map<uint32_t, std::string>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBMapEvent().subscribe([&](
        const std::unordered_map<uint32_t, std::string> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_MAP, 7, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::ready);
    EXPECT_EQ(f.get().size(), 7UL);
    testProxy_->getBMapEvent().unsubscribe(subscription);
}
/**
* @test Use a broadcast with a map. The broadcast tries to send too long a value.
*/
TEST_F(DeploymentTest, MapBroadcastDeploymentBadValue) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::unordered_map<uint32_t, std::string>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBMapEvent().subscribe([&](
        const std::unordered_map<uint32_t, std::string> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_MAP, 6, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::timeout);
    testProxy_->getBMapEvent().unsubscribe(subscription);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
