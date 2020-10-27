/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPArrayDeploymentTest
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
* @test Verify that the API for array deployments works
*/
TEST_F(DeploymentTest, ArrayWithDeployment) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed(nullptr, 0, 4, 0);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    uint32_t values[] = {10, 100, 1000, 10000};
    std::vector<uint32_t> outArray(values, values + 4);

    outStream.writeValue(outArray, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    std::vector<uint32_t> inArray;
    inStream.readValue(inArray, &ed);

    EXPECT_EQ(outArray, inArray);
}
/**
* @test Try to stream arrays that have a different number of elements that the deployment allows.
*/
TEST_F(DeploymentTest, ArrayWithWrongNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_0(nullptr, 0, 4, 0);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_1(nullptr, 3, 200, 1);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_2(nullptr, 5, 2000, 2);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_4(nullptr, 10, 200000, 4);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {1, 10, 100, 1000, 10000};
        std::vector<uint32_t> outArray(values, values + 5);

        outStream.writeValue(outArray, &ed_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {100, 1000, 10000};
        std::vector<uint32_t> outArray(values, values + 3);

        outStream.writeValue(outArray, &ed_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {100, 1000};
        std::vector<uint32_t> outArray(values, values + 2);

        outStream.writeValue(outArray, &ed_1);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(201, 0);

        outStream.writeValue(outArray, &ed_1);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {100, 1000, 10, 40};
        std::vector<uint32_t> outArray(values, values + 4);

        outStream.writeValue(outArray, &ed_2);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(2001, 1000);

        outStream.writeValue(outArray, &ed_2);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(9, 1000);

        outStream.writeValue(outArray, &ed_4);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(200001, 1000);

        outStream.writeValue(outArray, &ed_4);
        EXPECT_TRUE(outStream.hasError());
    }
}
/**
* @test Try to stream arrays that have a correct number of elements that the deployment allows.
*/
TEST_F(DeploymentTest, ArrayWithCorrectNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_0(nullptr, 0, 5, 0);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_1(nullptr, 3, 24, 1);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_2(nullptr, 5, 1000, 2);
    CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment> ed_4(nullptr, 10, 100000, 4);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {1, 10, 100, 1000, 10000};
        std::vector<uint32_t> outArray(values, values + 5);

        outStream.writeValue(outArray, &ed_0);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t values[] = {1, 10, 100};
        std::vector<uint32_t> outArray(values, values + 3);

        outStream.writeValue(outArray, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_1);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(22, 1000);

        outStream.writeValue(outArray, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_1);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(24, 1000);

        outStream.writeValue(outArray, &ed_1);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_1);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(5, 1000);

        outStream.writeValue(outArray, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(1000, 1000);

        outStream.writeValue(outArray, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(222, 12222);

        outStream.writeValue(outArray, &ed_2);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(10, 2222);

        outStream.writeValue(outArray, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(100000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        outStream.writeValue(outArray, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::vector<uint32_t> outArray(1000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        outStream.writeValue(outArray, &ed_4);
        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::vector<uint32_t> inArray;
        inStream.readValue(inArray, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(inArray.size(), outArray.size());

        EXPECT_EQ(outArray, inArray);
    }
}
/**
* @test Use an attribute with array deployment; transmit a correct number of elements.
*/
TEST_F(DeploymentTest, ArrayAttributeWithCorrectNumberOfElements) {

    CommonAPI::CallStatus callStatus;
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(10);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw0n0x10Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(20);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw0n5x20Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(0);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n0x15Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(1);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n0x15Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(15);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n0x15Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(10);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n10x200Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(63);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n10x200Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(15);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(1000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(2000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(400);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(20000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(200000);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
}
/**
* @test Use an attribute with array deployment; try to transmit an incorrect number of elements.
*/
TEST_F(DeploymentTest, ArrayAttributeWithWrongNumberOfElements) {

    CommonAPI::CallStatus callStatus;
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(9);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw0n0x10Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(4);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw0n5x20Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(21);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw0n5x20Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(16);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n0x15Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(9);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n10x200Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        // 64 elements is within legal limits, but the length of the total value does not fit in one byte.
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(64);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw1n10x200Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(14);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(2001);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(0);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw2n15x2000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(399);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(200001);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(0);
        std::iota (std::begin(outArray), std::end(outArray), 0);

        testProxy_->getAArrayw4n400x200000Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Use an attribute using an array with type deployment.
*/
TEST_F(DeploymentTest, ArrayAttributeWithTypeDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(5);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(200);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(4);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(201);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(5);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(200);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(4);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(201);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(1999);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(2000);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(2001);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32Attribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Use an attribute using an array with type deployment. The deployments set for the attribute should override the type deployments.
*/
TEST_F(DeploymentTest, ArrayAttributeDeplOverridesTypeDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(2000);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(1999);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(2001);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi8_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(2);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(2000);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(1);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int16_t> inArray;
        std::vector<int16_t> outArray(2001);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi16_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(15);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(200);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(14);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int32_t> inArray;
        std::vector<int32_t> outArray(201);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArrayi32_overrideAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Use an attribute using an anonymous array.
*/
TEST_F(DeploymentTest, ArrayAttributeDeplAnonymous) {

    CommonAPI::CallStatus callStatus;
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(2000);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArray_anonymousAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outArray, inArray);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(1999);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArray_anonymousAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::vector<int8_t> inArray;
        std::vector<int8_t> outArray(2001);
        std::iota (std::begin(outArray), std::end(outArray), 0);
        testProxy_->getAArray_anonymousAttribute().setValue(outArray, callStatus, inArray);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}

/**
* @test Use a method with an array as an argument. for both input and output.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_IO) {
    std::vector<int8_t> inArray;
    std::vector<int8_t> outArray(20);
    std::vector<int8_t> expectedArray(200);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 200);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 200);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_io(outArray, callStatus, inArray);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(expectedArray, inArray);
}

/**
* @test Use a method with an anonymous array as an argument. for both input and output.
*/
TEST_F(DeploymentTest, ArrayAnonMethodDeployment_IO) {
    std::vector<int8_t> inArray;
    std::vector<int8_t> outArray(20);
    std::vector<int8_t> expectedArray(200);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 200);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 200);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArray_anon_io(outArray, callStatus, inArray);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(expectedArray, inArray);
}
/**
* @test Us an method with an array as an argument. for both input and output. The input array is rejected by the deployment.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_IO_BadInput) {
    std::vector<int8_t> inArray;

    // the deployment insists on 20 elements, so this should fail.
    std::vector<int8_t> outArray(19);
    std::vector<int8_t> expectedArray(200);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 200);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 200);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_io(outArray, callStatus, inArray);

    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}

/**
* @test Us an method with an anonymous array as an argument. for both input and output. The input array is rejected by the deployment.
*/
TEST_F(DeploymentTest, ArrayAnonMethodDeployment_IO_BadInput) {
    std::vector<int8_t> inArray;

    // the deployment insists on 20 elements, so this should fail.
    std::vector<int8_t> outArray(19);
    std::vector<int8_t> expectedArray(200);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 200);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 200);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArray_anon_io(outArray, callStatus, inArray);

    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}
/**
* @test Use a method with an array as an argument. for both input and output. The output array is rejected by the deployment.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_IO_BadOutput) {
    std::vector<int8_t> inArray;

    // the deployment insists on 20 elements
    std::vector<int8_t> outArray(20);
    std::vector<int8_t> expectedArray(199);

    // the first byte in the output array tells how many items should be in the incoming array
    // the deployment insists on 200 bytes, so this should fail
    // the failure is on the stub side, so it shows up as a timeout error
    std::iota (std::begin(outArray), std::end(outArray), 199);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 199);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_io(outArray, callStatus, inArray);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);

}
/**
* @test Use a method with an anonymous array as an argument. for both input and output. The output array is rejected by the deployment.
*/
TEST_F(DeploymentTest, ArrayAnonMethodDeployment_IO_BadOutput) {
    std::vector<int8_t> inArray;

    // the deployment insists on 20 elements
    std::vector<int8_t> outArray(20);
    std::vector<int8_t> expectedArray(199);

    // the first byte in the output array tells how many items should be in the incoming array
    // the deployment insists on 200 bytes, so this should fail
    // the failure is on the stub side, so it shows up as a timeout error
    std::iota (std::begin(outArray), std::end(outArray), 199);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 199);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArray_anon_io(outArray, callStatus, inArray);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);

}
/**
* @test Use a method with an array as an argument. for either input or output.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_I_O) {
    std::vector<int8_t> inArray;
    std::vector<int8_t> outArray(10);
    std::vector<int8_t> expectedArray(100);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 100);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 100);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_i(outArray, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mArrayi8_o(callStatus, inArray);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(expectedArray, inArray);
}
/**
* @test Use a method with an array as an input argument. Pass faulty input.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_I_O_BadInput) {
    std::vector<int8_t> inArray;
    // deployment insists on 10 bytes, so this should fail
    std::vector<int8_t> outArray(9);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 100);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_i(outArray, callStatus);
    EXPECT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
}
/**
* @test Use a method with an array as an output argument. Pass faulty output.
*/
TEST_F(DeploymentTest, ArrayMethodDeployment_I_O_BadOutput) {
    std::vector<int8_t> inArray;
    std::vector<int8_t> outArray(10);
    // deployment insists on 100 bytes, so this should fail
    std::vector<int8_t> expectedArray(101);

    // the first byte in the output array tells how many items should be in the incoming array
    std::iota (std::begin(outArray), std::end(outArray), 101);
    std::iota (std::begin(expectedArray), std::end(expectedArray), 101);

    CommonAPI::CallStatus callStatus;
    testProxy_->mArrayi8_i(outArray, callStatus);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    testProxy_->mArrayi8_o(callStatus, inArray);
    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}

/**
* @test Use a broadcast with an array as an output argument.
*/
TEST_F(DeploymentTest, ArrayBroadcastDeployment) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::vector<int8_t>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBArrayi8Event().subscribe([&](
        const std::vector<int8_t> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_ARRAY, 100, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::ready);
    EXPECT_EQ(f.get().size(), 100UL);
    testProxy_->getBArrayi8Event().unsubscribe(subscription);
}
/**
* @test Use a broadcast with an array. The broadcast tries to send too long a value.
*/
TEST_F(DeploymentTest, ArrayBroadcastDeploymentBadValue) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::vector<int8_t>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBArrayi8Event().subscribe([&](
        const std::vector<int8_t> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_ARRAY, 600, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::timeout);
    testProxy_->getBArrayi8Event().unsubscribe(subscription);
}

/**
* @test Use a broadcast with an anonymous array as an output argument.
*/
TEST_F(DeploymentTest, ArrayAnonBroadcastDeployment) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::vector<int8_t>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBArray_anonEvent().subscribe([&](
        const std::vector<int8_t> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_ANON, 100, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::ready);
    EXPECT_EQ(f.get().size(), 100UL);
    testProxy_->getBArray_anonEvent().unsubscribe(subscription);
}
/**
* @test Use a broadcast with an anonymous array. The broadcast tries to send too long a value.
*/
TEST_F(DeploymentTest, ArrayAnonBroadcastDeploymentBadValue) {

    CommonAPI::CallStatus callStatus;
    std::promise<std::vector<int8_t>> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBArray_anonEvent().subscribe([&](
        const std::vector<int8_t> &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_ANON, 600, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::timeout);
    testProxy_->getBArray_anonEvent().unsubscribe(subscription);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
