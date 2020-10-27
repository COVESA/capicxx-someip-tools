/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPEnumDeploymentTest
*/

#include <functional>
#include <condition_variable>
#include <mutex>
#include <thread>
#include <fstream>
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
* @test Verify that the API for enum deployments works. Stream various enums with different deployments.
*/
TEST_F(DeploymentTest, EnumWithDeployment) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32i(32, false, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16i(16, false, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8i(8, false, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32(32, false);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16(16, false);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8(8, false);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32is(32, true, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16is(16, true, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8is(8, true, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32s(32, true);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16s(16, true);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8s(8, true);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_32i);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32i);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_16i);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16i);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_8i);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8i);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_32);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_16);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_8);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_32is);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32is);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_16is);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16is);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_8is);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8is);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_32s);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32s);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_16s);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16s);

        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);

        outStream.writeValue(outv, &ed_8s);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8s);

        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Stream various invalid enums. Check that the 'invalid value' given in deployment is returned.
*/
TEST_F(DeploymentTest, EnumInvalidValue) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32i(32, false, -1);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16i(16, false, -2);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8i(8, false, -3);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_32is(32, true, -4);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_16is(16, true, -5);
    CommonAPI::SomeIP::EnumerationDeployment<int32_t> ed_8is(8, true, -6);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        CommonAPI::EmptyDeployment ed;
        outStream.writeValue((uint8_t)123, &ed);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32i);

        EXPECT_EQ(-1, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        CommonAPI::EmptyDeployment ed;
        outStream.writeValue((uint8_t)123, &ed);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16i);

        EXPECT_EQ(-2, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8i);

        EXPECT_EQ(-3, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        CommonAPI::EmptyDeployment ed;
        outStream.writeValue((uint16_t)1234, &ed);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_32is);

        EXPECT_EQ(-4, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        CommonAPI::EmptyDeployment ed;
        outStream.writeValue((uint8_t)234, &ed);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_16is);

        EXPECT_EQ(-5, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;
        inStream.readValue(inv, &ed_8is);

        EXPECT_EQ(-6, inv);
    }
}
/**
* @test Use an attribute with enum type. Try out various type deployments.
*/
TEST_F(DeploymentTest, EnumAttributeWithTypeDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum4_16 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum4_16::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum4_16 inv;

        testProxy_->getAEnum4_16Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum4_32 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum4_32::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum4_32 inv;

        testProxy_->getAEnum4_32Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_8 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum2_8::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_8 inv;

        testProxy_->getAEnum2_8Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_16 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum2_16::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_16 inv;

        testProxy_->getAEnum2_16Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_8 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum1_8::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_8 inv;

        testProxy_->getAEnum1_8Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum1_1::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 inv;

        testProxy_->getAEnum1_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum1_1::V3);
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 inv;

        testProxy_->getAEnum1_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        // the value is clipped to zero because the deployment ensures that only one bit is sent.
        EXPECT_EQ(0, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum1_1::V4);
        @TYPE_COLLECTION_FULL_NAME@::tEnum1_1 inv;

        testProxy_->getAEnum1_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        // the value is clipped to one because the deployment ensures that only one bit is sent.
        EXPECT_EQ(1, inv);
    }
}
/**
* @test Use an attribute with enum type, with a deployment given in the attribute.
*/
TEST_F(DeploymentTest, EnumAttributeWithAttrDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum outv(@TYPE_COLLECTION_FULL_NAME@::tEnum::V1);
        @TYPE_COLLECTION_FULL_NAME@::tEnum inv;

        testProxy_->getAEnumAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Check that attribute-specific deployment overrides type-specific deployment for enums.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_EnumAttrDeplOverridesTypeDepl) {

    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_8 outv(@TYPE_COLLECTION_FULL_NAME@::tEnum2_8::V2);
        @TYPE_COLLECTION_FULL_NAME@::tEnum2_8 inv;

        testProxy_->getAEnum_overrideAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        // the values won't be the same because the deployment clips some bits off the value.
        EXPECT_NE(outv, inv);
        // in fact, the resulting value will be equal to V3 which is the bit-clipped version of V2
        EXPECT_EQ(@TYPE_COLLECTION_FULL_NAME@::tEnum2_8::V3, inv);
    }
}
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
