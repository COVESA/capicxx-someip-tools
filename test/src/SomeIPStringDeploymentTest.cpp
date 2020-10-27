/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPStringDeploymentTest
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
* @test Verify that the API for string deployments works
*/
TEST_F(DeploymentTest, StringWithDeployment) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 0, CommonAPI::SomeIP::StringEncoding::UTF8);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 1, CommonAPI::SomeIP::StringEncoding::UTF8);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 2, CommonAPI::SomeIP::StringEncoding::UTF8);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 4, CommonAPI::SomeIP::StringEncoding::UTF8);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 4, CommonAPI::SomeIP::StringEncoding::UTF16BE);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::StringDeployment depl(10, 4, CommonAPI::SomeIP::StringEncoding::UTF16LE);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        std::string outv = "abcdef";

        outStream.writeValue(outv, &depl);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        std::string inv;
        inStream.readValue(inv, &depl);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify that string encoding works as given in the deployment.
*/
TEST_F(DeploymentTest, StringEncodingDeployment) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::StringDeployment deplutf8(10, 1, CommonAPI::SomeIP::StringEncoding::UTF8);
        CommonAPI::SomeIP::StringDeployment deplutf16be(10, 1, CommonAPI::SomeIP::StringEncoding::UTF16BE);
        CommonAPI::SomeIP::StringDeployment deplutf16le(10, 1, CommonAPI::SomeIP::StringEncoding::UTF16LE);

        // a valid UTF-8 encoded string
        std::string outv = "abcdef\xe2\x82\xac";
        {
            CommonAPI::SomeIP::byte_t expected[] = {13, 239, 187, 191, 97, 98, 99, 100, 101, 102, 226, 130, 172, 0};
            CommonAPI::SomeIP::OutputStream outStream(message, false);
            outStream.writeValue(outv, &deplutf8);
            EXPECT_FALSE(outStream.hasError());
            outStream.flush();

            CommonAPI::SomeIP::byte_t * data = message.getBodyData();
            CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
            EXPECT_EQ(length, sizeof expected);

            for (unsigned int i = 0; i < length; i++) {
                EXPECT_EQ(data[i], expected[i]);
                // std::cout << (unsigned int)data[i] << ", ";
            }
            std::cout << std::endl;

            CommonAPI::SomeIP::InputStream inStream(message, false);

            std::string inv;
            inStream.readValue(inv, &deplutf8);
            EXPECT_FALSE(inStream.hasError());
            EXPECT_EQ(outv, inv);
        }
        {
            CommonAPI::SomeIP::byte_t expected[] = {18, 254, 255, 0, 97, 0, 98, 0, 99, 0, 100, 0, 101, 0, 102, 32, 172, 0, 0};
            CommonAPI::SomeIP::OutputStream outStream(message, false);
            outStream.writeValue(outv, &deplutf16be);
            EXPECT_FALSE(outStream.hasError());
            outStream.flush();

            CommonAPI::SomeIP::byte_t * data = message.getBodyData();
            CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
            EXPECT_EQ(length, sizeof expected);

            for (unsigned int i = 0; i < length; i++) {
                EXPECT_EQ(data[i], expected[i]);
                // std::cout << (unsigned int)data[i] << ", ";
            }
            std::cout << std::endl;

            CommonAPI::SomeIP::InputStream inStream(message, false);

            std::string inv;
            inStream.readValue(inv, &deplutf16be);
            EXPECT_FALSE(inStream.hasError());
            EXPECT_EQ(outv, inv);
        }
        {
            CommonAPI::SomeIP::byte_t expected[] = {18, 255, 254, 97, 0, 98, 0, 99, 0, 100, 0, 101, 0, 102, 0, 172, 32, 0, 0};
            CommonAPI::SomeIP::OutputStream outStream(message, false);
            outStream.writeValue(outv, &deplutf16le);
            EXPECT_FALSE(outStream.hasError());
            outStream.flush();

            CommonAPI::SomeIP::byte_t * data = message.getBodyData();
            CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
            EXPECT_EQ(length, sizeof expected);

            for (unsigned int i = 0; i < length; i++) {
                EXPECT_EQ(data[i], expected[i]);
                // std::cout << (unsigned int)data[i] << ", ";
            }
            std::cout << std::endl;

            CommonAPI::SomeIP::InputStream inStream(message, false);

            std::string inv;
            inStream.readValue(inv, &deplutf16le);
            EXPECT_FALSE(inStream.hasError());
            EXPECT_EQ(outv, inv);
        }
    }
}

TEST_F(DeploymentTest, StringWithNULCodepoint) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::StringDeployment deplutf8(10, 1, CommonAPI::SomeIP::StringEncoding::UTF8);

        // a valid UTF-8 encoded string
        std::string outv = std::string("abc\0def\xe2\x82\xac", 10);
        {
            CommonAPI::SomeIP::byte_t expected[] = {14, 239, 187, 191, 97, 98, 99, 0, 100, 101, 102, 226, 130, 172, 0};
            CommonAPI::SomeIP::OutputStream outStream(message, false);
            outStream.writeValue(outv, &deplutf8);
            EXPECT_FALSE(outStream.hasError());
            outStream.flush();

            CommonAPI::SomeIP::byte_t * data = message.getBodyData();
            CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
            EXPECT_EQ(length, sizeof expected);

            for (unsigned int i = 0; i < length; i++) {
                EXPECT_EQ(data[i], expected[i]);
                // std::cout << (unsigned int)data[i] << ", ";
            }
            //std::cout << std::endl;

            CommonAPI::SomeIP::InputStream inStream(message, false);

            std::string inv;
            inStream.readValue(inv, &deplutf8);
            EXPECT_FALSE(inStream.hasError());
            EXPECT_EQ(outv, inv);
        }
    }
}

/**
* @test Pass an attribute with string value and a deployment.
*/
TEST_F(DeploymentTest, StringAttributeWithDeployment) {

    CommonAPI::CallStatus callStatus;
    {
        // the attribute has a fixed data length of 10,
        // which includes the encoding (3 bytes) and the trailing NUL
        // this leaves room for 6 one-byte-length characters.
        std::string outv = "012345";
        std::string inv;

        testProxy_->getAString_l10_w0Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        // the attribute has a fixed data length of 10,
        // which includes the encoding (3 bytes) and the trailing NUL
        // this leaves room for 6 one-byte-length characters.
        // We'll send a five-letter string.
        // This is nowadays okay, if the rest of the data is filled with zeros.
        std::string outv = "01234";
        std::string inv;

        testProxy_->getAString_l10_w0Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        outv.append(1, '\0');
        EXPECT_EQ(outv, inv);
    }
    {
        // the attribute has a fixed data length of 10,
        // which includes the encoding (3 bytes) and the trailing NUL
        // this leaves room for 6 one-byte-length characters.
        // A longer string is considered an error.
        std::string outv = "0123456";
        std::string inv;

        testProxy_->getAString_l10_w0Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::string outv = "0123456789";
        std::string inv;

        testProxy_->getAString_w1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        // too long a string, according to deployment
        std::string outv(256, 'a');
        std::string inv;

        testProxy_->getAString_w1Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::string outv(256, 'a');
        std::string inv;

        testProxy_->getAString_w2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        std::string outv(65536, 'a');
        std::string inv;

        testProxy_->getAString_w2Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        std::string outv(655360, 'a');
        std::string inv;

        testProxy_->getAString_w4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        std::string outv = "abcdef\xe2\x82\xac";
        std::string inv;

        testProxy_->getAString_utf8Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        std::string outv = "abcdef\xe2\x82\xac";
        std::string inv;

        testProxy_->getAString_utf16_beAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        std::string outv = "abcdef\xe2\x82\xac";
        std::string inv;

        testProxy_->getAString_utf16_leAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
