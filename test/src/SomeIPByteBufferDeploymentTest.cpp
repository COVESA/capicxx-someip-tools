/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPByteBufferDeploymentTest
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
#include "v1/commonapi/someip/deploymenttest/TestInterfaceStubDefault.hpp"

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

        testStub_ = std::make_shared<v1_0::commonapi::someip::deploymenttest::TestInterfaceStubDefault>();
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
        ASSERT_TRUE(runtime_->unregisterService(domain, v1_0::commonapi::someip::deploymenttest::TestInterfaceStubDefault::StubInterface::getInterface(), testAddress));

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
    std::shared_ptr<v1_0::commonapi::someip::deploymenttest::TestInterfaceStubDefault> testStub_;
};
/**
* @test Verify that the API for byte buffer deployments works
*/
TEST_F(DeploymentTest, ByteBufferWithDeployment) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ByteBufferDeployment ed(0, 0);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4, 5};

    outStream.writeValue(outByteBuffer, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    CommonAPI::ByteBuffer inByteBuffer;
    inStream.readValue(inByteBuffer, &ed);

    EXPECT_EQ(outByteBuffer, inByteBuffer);
}
/**
* @test Verify that the API for byte buffer deployments works with empty deployment.
*/
TEST_F(DeploymentTest, ByteBufferWithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4, 5};

    outStream.writeValue(outByteBuffer, static_cast<CommonAPI::SomeIP::ByteBufferDeployment *>(nullptr));
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    CommonAPI::ByteBuffer inByteBuffer;
    inStream.readValue(inByteBuffer, static_cast<CommonAPI::SomeIP::ByteBufferDeployment *>(nullptr));

    EXPECT_EQ(outByteBuffer, inByteBuffer);
}
/**
* @test Try to stream byte buffers that don't match the given deployment.
*/
TEST_F(DeploymentTest, ByteBufferWithWrongNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_0(4, 0);
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_4(4, 4);
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_9(4, 9);
    CommonAPI::SomeIP::ByteBufferDeployment ed_0_9(0, 9);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2};
        outStream.writeValue(outByteBuffer, &ed_4_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {};
        outStream.writeValue(outByteBuffer, &ed_4_0);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2};
        outStream.writeValue(outByteBuffer, &ed_4_4);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4};
        outStream.writeValue(outByteBuffer, &ed_4_4);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2};
        outStream.writeValue(outByteBuffer, &ed_4_9);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
        outStream.writeValue(outByteBuffer, &ed_4_9);
        EXPECT_TRUE(outStream.hasError());
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
        outStream.writeValue(outByteBuffer, &ed_0_9);
        EXPECT_TRUE(outStream.hasError());
    }
}
/**
* @test Try to stream byte buffers with various deployments.
*/
TEST_F(DeploymentTest, ByteBufferWithCorrectNumberOfElements) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_0(4, 0);
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_4(4, 4);
    CommonAPI::SomeIP::ByteBufferDeployment ed_4_9(4, 9);
    CommonAPI::SomeIP::ByteBufferDeployment ed_0_99999(0, 99999);
    CommonAPI::SomeIP::ByteBufferDeployment ed_0_0(0, 0);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3};
        outStream.writeValue(outByteBuffer, &ed_4_0);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_4_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4};
        outStream.writeValue(outByteBuffer, &ed_4_0);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_4_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3};
        outStream.writeValue(outByteBuffer, &ed_4_4);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_4_4);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3};
        outStream.writeValue(outByteBuffer, &ed_4_9);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_4_9);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {0, 1, 2, 3, 4, 5, 6, 7, 8};
        outStream.writeValue(outByteBuffer, &ed_4_9);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_4_9);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {};
        outStream.writeValue(outByteBuffer, &ed_0_99999);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_0_99999);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer(99999);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        outStream.writeValue(outByteBuffer, &ed_0_99999);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_0_99999);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer = {};
        outStream.writeValue(outByteBuffer, &ed_0_0);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_0_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::ByteBuffer outByteBuffer(99999);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        outStream.writeValue(outByteBuffer, &ed_0_0);

        EXPECT_FALSE(outStream.hasError());

        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::ByteBuffer inByteBuffer;
        inStream.readValue(inByteBuffer, &ed_0_0);
        EXPECT_FALSE(inStream.hasError());

        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
}
/**
* @test Try to transmit an attribute with a byte buffer, with various kinds of deployments.
*/
TEST_F(DeploymentTest, ByteBufferAttributeWithCorrectNumberOfBytes) {

    CommonAPI::CallStatus callStatus;
    {
        CommonAPI::ByteBuffer outByteBuffer(99999);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBdefaultAttribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(88888);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer = {};
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(10);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 5);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn10x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(100);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 50);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn10x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(10);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 50);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x10Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer = {};
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x10Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer = {5};
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x10Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(5);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn5x20Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(20);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn5x20Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(100000);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn100000x100000Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outByteBuffer, inByteBuffer);
    }
}
/**
* @test Try to transmit an attribute with a byte buffer, where the deployment rejects the buffer.
*/
TEST_F(DeploymentTest, ByteBufferAttributeWithIncorrectNumberOfBytes) {

    CommonAPI::CallStatus callStatus;
    {
        CommonAPI::ByteBuffer outByteBuffer(9);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 0);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn10x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer = {};
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn10x0Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(11);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn0x10Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(4);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn5x20Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(21);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn5x20Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(99999);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn100000x100000Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(100001);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn100000x100000Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer(9);
        std::iota (std::begin(outByteBuffer), std::end(outByteBuffer), 1);
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn100000x100000Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        CommonAPI::ByteBuffer outByteBuffer = {};
        CommonAPI::ByteBuffer inByteBuffer;

        testProxy_->getABBn100000x100000Attribute().setValue(outByteBuffer, callStatus, inByteBuffer);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
