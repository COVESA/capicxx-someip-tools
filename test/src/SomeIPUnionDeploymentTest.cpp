/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPUnionDeploymentTest
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
* @test Verify that the API for union deployments works
*/
TEST_F(DeploymentTest, UnionWithDeployment) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(4, 1, true, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(4, 1, false, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(2, 1, true, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(2, 1, false, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(1, 1, true, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(1, 1, false, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(0, 1, true, 1, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(0, 2, false, 2, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        int16_t value = 1;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Stream some union data with various deployments.
*/
TEST_F(DeploymentTest, UnionWithOutputDeployment) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(4, 1, true, 12, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            0, 0, 0, 11, /* = length of data in bytes - four bytes specified in the deployment */
            3, /* =  data type = 3, for string. Deployment specifices just one data type byte. */
            0, 0, 0, 7, /* length of string including BOM and ending NUL */
            239, 187, 191, /* BOM of UTF-8 */
            49, 50, 51, 0 /* '1', '2', '3', NUL */
        };

        std::string value = "123";
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        ASSERT_EQ(sizeof expected_data, length);
        for (unsigned int i = 0; i < length; i++) {
            EXPECT_EQ(expected_data[i], data[i]);
        }

    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(1, 2, false, 10, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            0, 3, /* =  data type = 3, for string. Deployment specifices two data type bytes. */
            11, /* = length of data in bytes - one byte specified in the deployment */
            0, 0, 0, 7, /* length of string including BOM and ending NUL */
            239, 187, 191, /* BOM of UTF-8 */
            49, 50, 51, 0 /* '1', '2', '3', NUL */
        };

        std::string value = "123";
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        ASSERT_EQ(sizeof expected_data, length);
        for (unsigned int i = 0; i < length; i++) {
            // std::cout << (unsigned int)(data[i]) << " ";
            EXPECT_EQ(expected_data[i], data[i]);
        }

    }
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(0, 1, false, 11, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            3, /* =  data type = 3, for string. Deployment specifices one data type  */
            /* no data length. */
            0, 0, 0, 7, /* length of string including BOM and ending NUL */
            239, 187, 191, /* BOM of UTF-8 */
            49, 50, 51, 0 /* '1', '2', '3', NUL */
        };

        std::string value = "123";
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        ASSERT_EQ(sizeof expected_data, length);
        for (unsigned int i = 0; i < length; i++) {
            // std::cout << (unsigned int)(data[i]) << " ";
            EXPECT_EQ(expected_data[i], data[i]);
        }
    }
}
/**
* @test Stream some struct data with various deployments. Give too many data.
*/
TEST_F(DeploymentTest, UnionWithTooSmallMaxLength) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(0, 1, true, 2, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string value = "123";
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_TRUE(outStream.hasError());
    }
}
/**
* @test Stream some struct data with various deployments. Give too large data.
*/
TEST_F(DeploymentTest, UnionWithTooSmallLengthWidth) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::VariantDeployment<CommonAPI::SomeIP::IntegerDeployment<uint8_t>,
              CommonAPI::SomeIP::IntegerDeployment<int16_t>,
              CommonAPI::SomeIP::StringDeployment> depl(1, 1, true, 2, nullptr, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string value (256, 'c');

        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        outv = value;
        outStream.writeValue(outv, &depl);
        EXPECT_TRUE(outStream.hasError());
    }
}
/**
* @test Pass an attribute with union type data with attribute deployment.
*/
TEST_F(DeploymentTest, UnionAttributeDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_1 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_2 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_2 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_3 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_3 inv;

        // this will fail because the deployment specifies an 11-byte value length.
        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_3Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

        // this will fail because the deployment specifies an 11-byte value length.
        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_3Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

        // this will succeed because the deployment specifies an 11-byte value length.
        // the length of the string value is (4 bytes for string length) + (3 bytes for BOM UTF-8) + (number of characters) + NUL
        std::string v3 = "Hel";
        outv = v3;

        testProxy_->getAUnion_3Attribute().setValue(outv, callStatus, inv);
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_4 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_4 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Pass an attribute with union type data with type deployment.
*/
TEST_F(DeploymentTest, UnionTypeDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d1 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d1 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_d1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_d1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_d1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_d2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_d2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_d2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 inv;

        // this will fail because the deployment specifies an 12-byte value length.
        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_d3Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

        // this will fail because the deployment specifies an 12-byte value length.
        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_d3Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

        // this will succeed because the deployment specifies an 12-byte value length.
        // the length of the string value is (4 bytes for string length) + (3 bytes for BOM UTF-8) + (number of characters) + NUL
        std::string v3 = "Ciao";
        outv = v3;

        testProxy_->getAUnion_d3Attribute().setValue(outv, callStatus, inv);
        EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d4 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d4 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_d4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -100;
        outv = v2;

        testProxy_->getAUnion_d4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_d4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify that attribute union deployment overrides type deployment.
*/
TEST_F(DeploymentTest, UnionAttributeDeplOverridesTypeDepl) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 outv;
        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 inv;

        uint8_t v1 = 1;
        outv = v1;

        testProxy_->getAUnion_overrideAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        int16_t v2 = -123;
        outv = v2;

        testProxy_->getAUnion_overrideAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);

        // the following will fail if the attribute's deployment does not override the type deployment.
        std::string v3 = "Hello World";
        outv = v3;

        testProxy_->getAUnion_overrideAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionStruct...') works (good case)
*/
TEST_F(DeploymentTest, UnionStructFieldDeploymentOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv = structMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionStruct...') (failure case))
*/
TEST_F(DeploymentTest, UnionStructFieldDeploymentFail) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        // the following value is too large and should fail when transmitted.
        std::vector<uint8_t> a(257);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv = structMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionArray...') for array members.
*/
TEST_F(DeploymentTest, UnionArrayFieldDeploymentOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        // this value is too large, and the value should not be transmitted.
        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv = arrayMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionArray...') for array members. (failure case)
*/
TEST_F(DeploymentTest, UnionArrayFieldDeploymentFail) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        // this value is too large, and the value should not be transmitted.
        std::vector<int8_t> arrayMember(80);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv = arrayMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionUnion...') for union members.
*/
TEST_F(DeploymentTest, UnionUnionFieldDeploymentOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv = unionMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionUnion...') for union members. (failure case)
*/
TEST_F(DeploymentTest, UnionUnionFieldDeploymentFail) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        // this value is too large, and the value should not be transmitted.
        std::string str(70000, 'a');
        unionMember = str;
        outv = unionMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionInt...') for integer members.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UnionIntFieldDeploymentOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        uint16_t intMember;
        intMember = 3;
        outv = intMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionInt...') for integer members. (failure case)
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UnionIntFieldDeploymentFail) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        uint16_t intMember;
        intMember = 5; // this value will be truncated during transfer.
        outv = intMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls expected;
        uint16_t inInt = 1;
        expected = inInt;
        ASSERT_EQ(expected, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionEnum...') for enum members.
*/
TEST_F(DeploymentTest, UnionEnumFieldDeploymentOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv = enumMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify union field deployments ('SomeIpUnionEnum...') for enum members. (failure case)
*/
TEST_F(DeploymentTest, UnionEnumFieldDeploymentFail) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        // this enum value is too large to fit. It will be truncated during transfer.
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V3;
        outv = enumMember;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls inv;
        testProxy_->getAUnion_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field_depls expected;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::VTRUNCATED;
        expected = enumMember;
        ASSERT_EQ(expected, inv);
    }
}

/**
* @test Use a method with an union as an argument. for both input and output.
*/
TEST_F(DeploymentTest, UnionMethodDeployment_IO) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 inv;

    std::string str(492, 'a');
    outv = str;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_io(outv, callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(outv, inv);
}
TEST_F(DeploymentTest, UnionMethodDeployment_I) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;

    std::string str(492, 'a');
    outv = str;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_i(outv, callStatus);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

}
TEST_F(DeploymentTest, UnionMethodDeployment_O) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 inv;

    std::string str(492, 'a');
    outv = str;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_o(callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(outv, inv);
}
TEST_F(DeploymentTest, UnionMethodDeployment_IO_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 inv;

    std::string str(600, 'a');
    outv = str;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_io(outv, callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SERIALIZATION_ERROR);
}
TEST_F(DeploymentTest, UnionMethodDeployment_I_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 outv;

    std::string str(600, 'a');
    outv = str;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_i(outv, callStatus);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SERIALIZATION_ERROR);

}
TEST_F(DeploymentTest, UnionMethodDeployment_O_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 inv;

    CommonAPI::CallStatus callStatus;
    testProxy_->mUnion_of(callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}

/**
* @test Use a broadcast with a union.
*/
TEST_F(DeploymentTest, UnionBroadcastDeployment) {

    CommonAPI::CallStatus callStatus;
    std::promise<@TYPE_COLLECTION_FULL_NAME@::tUnion_d2> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBUnionEvent().subscribe([&](
        const @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_UNION, 492, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::ready);
    testProxy_->getBUnionEvent().unsubscribe(subscription);
}

/**
* @test Use a broadcast with a union. Will fail on purpose.
*/
TEST_F(DeploymentTest, UnionBroadcastDeploymentBadValue) {

    CommonAPI::CallStatus callStatus;
    std::promise<@TYPE_COLLECTION_FULL_NAME@::tUnion_d2> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBUnionEvent().subscribe([&](
        const @TYPE_COLLECTION_FULL_NAME@::tUnion_d2 &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_UNION, 600, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::timeout);
    testProxy_->getBUnionEvent().unsubscribe(subscription);
}


int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
