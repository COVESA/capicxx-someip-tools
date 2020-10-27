/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPIntegerDeploymentTest
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
* @test Verify that the API for integer deployment works for UInt8 type and empty deployment.
*/
TEST_F(DeploymentTest, UInt8WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    uint8_t val1 = 0xA5;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    uint8_t exp1 = 0xFF;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Verify that the API for integer deployment works for Int8 type and empty deployment.
*/
TEST_F(DeploymentTest, Int8WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    int8_t val1 = (int8_t)0xA5;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    int8_t exp1 = 0;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Check that an UInt8 data is clipped according to bit length output deployment.
*/
TEST_F(DeploymentTest, UInt8WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 8; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t val1 = 0xFF;
        CommonAPI::SomeIP::IntegerDeployment<uint8_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            EXPECT_EQ(data[0], (CommonAPI::SomeIP::byte_t)((1 << i) - 1));
        }
    }
    // any bit length greater than 8 should be clipped to 8 bits
    for (uint8_t i = 9; i <= 32; i++) {
         message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t val1 = 0xFF;
        CommonAPI::SomeIP::IntegerDeployment<int8_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();

        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)(1));
        if (length == 1) {
            EXPECT_EQ(data[0], (CommonAPI::SomeIP::byte_t) 0xFF);
        }
    }
}
/**
* @test Check that an Int8 data is clipped according to bit length output deployment.
*/
TEST_F(DeploymentTest, Int8WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    // note that minimum bit length for signed integers is 2.
    for (uint8_t i = 2; i <= 8; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        int8_t val1 = (int8_t)0xFF;
        CommonAPI::SomeIP::IntegerDeployment<int8_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();

        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            EXPECT_EQ(data[0], (CommonAPI::SomeIP::byte_t)((1 << i) - 1));
        }
    }

    // any bit length greater than 8 should be clipped to 8 bits
    for (uint8_t i = 9; i <= 32; i++) {
         message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        int8_t val1 = (int8_t)0xFF;
        CommonAPI::SomeIP::IntegerDeployment<int8_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();

        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)(1));
        if (length == 1) {
            EXPECT_EQ(data[0], (CommonAPI::SomeIP::byte_t) 0xFF);
        }
    }
}


/**
* @test Check that an UInt8 data is clipped according to bit length input and output deployments.
*/
TEST_F(DeploymentTest, UInt8WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 8; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t val1 = 0xFF;
        CommonAPI::SomeIP::IntegerDeployment<uint8_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<uint8_t> id(i);
        uint8_t exp1 = 0x00;
        inStream.readValue(exp1, &id);

        EXPECT_EQ((1 << i) - 1, exp1);
    }

    // try another bit pattern to make sure that correct bits are returned
    for (uint8_t i = 1; i <= 8; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint8_t val1 = 0xA5;
        CommonAPI::SomeIP::IntegerDeployment<uint8_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<uint8_t> id(i);
        uint8_t exp1 = 0x0000;
        inStream.readValue(exp1, &id);

        EXPECT_EQ(val1 & ((1<<i)-1), exp1);
    }
}
/**
* @test Check that an Int8 data is clipped according to bit length input and output deployments.
*/
TEST_F(DeploymentTest, Int8WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 8; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        int8_t val1 = (int8_t)(0x69 & ((1 << i) - 1));
        CommonAPI::SomeIP::IntegerDeployment<int8_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<int8_t> id(i);
        int8_t exp1 = (int8_t)0x00;
        inStream.readValue(exp1, &id);
        exp1 = (int8_t)(exp1 & ((1 << i) - 1));
        // std::cout << (uint16_t) i << ": " << (uint16_t) val1 << " " << (uint16_t) exp1 << std::endl;
        EXPECT_EQ(val1, exp1);
    }
}
/**
* @test Verify that the API for integer deployment works for UInt16 type and empty deployment.
*/
TEST_F(DeploymentTest, UInt16WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    uint16_t val1 = 0xA55A;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    uint16_t exp1 = 0xFFFF;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Verify that the API for integer deployment works for Int16 type and empty deployment.
*/
TEST_F(DeploymentTest, Int16WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    int16_t val1 = (int16_t)0xA55A;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    int16_t exp1 = (int16_t)0xFFFF;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Check that an UInt16 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt16WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 16; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint16_t mask = (uint16_t)((1 << (uint16_t)i) - 1);
        uint16_t val1 = (uint16_t)(0x9876 & mask);
        CommonAPI::SomeIP::IntegerDeployment<uint16_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[0] << std::endl;
            EXPECT_EQ(data[0], val1 & 0xFF);
        }
        if (length == 2) {
            // std::cout << std::hex << (uint16_t) i << ": " << ((val1 & 0xFF00) >> 8) << " " << (uint16_t) data[0] << std::endl;
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[1] << std::endl;

            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[1], val1 & 0xFF);
        }
    }
}
/**
* @test Check that an Int16 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int16WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 16; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint16_t mask = (uint16_t)((1 << (uint16_t)i) - 1);
        int16_t val1 = (int16_t)(0xABCD & mask);
        CommonAPI::SomeIP::IntegerDeployment<int16_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[0] << std::endl;
            EXPECT_EQ(data[0], val1 & 0xFF);
        }
        if (length == 2) {
            // std::cout << std::hex << (uint16_t) i << ": " << ((val1 & 0xFF00) >> 8) << " " << (uint16_t) data[0] << std::endl;
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[1] << std::endl;

            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[1], val1 & 0xFF);
        }
    }
}

/**
* @test Check that an UInt16 data comes back intact when streamed.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt16WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 16; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        uint16_t mask = (uint16_t)((1 << (uint16_t)i) - 1);
        uint16_t val1 = (uint16_t)(0x8765 & mask);
        CommonAPI::SomeIP::IntegerDeployment<uint16_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<uint16_t> id(i);
        uint16_t exp1 = 0x0000;
        inStream.readValue(exp1, &id);
        exp1 = exp1 & mask;
        // std::cout << std::hex << (uint16_t) i << ": " << val1 << " " << exp1 << std::endl;

        EXPECT_EQ(val1, exp1);
    }

}
/**
* @test Check that an Int16 data is clipped according to bit length input and output deployments.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int16WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 16; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        uint16_t mask = (uint16_t)((1 << (uint16_t)i) - 1);
        int16_t val1 = (int16_t)(0x8765 & mask);
        CommonAPI::SomeIP::IntegerDeployment<int16_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<int16_t> id(i);
        int16_t exp1 = 0x0000;
        inStream.readValue(exp1, &id);
        exp1 = (int16_t)(exp1 & mask);
        // std::cout << std::hex << (uint16_t) i << ": " << val1 << " " << exp1 << std::endl;

        EXPECT_EQ(val1, exp1);
    }
}
/**
* @test Verify that the API for integer deployment works for UInt32 type and empty deployment.
*/
TEST_F(DeploymentTest, UInt32WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    uint32_t val1 = 0xA55A6996;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    uint32_t exp1 = 0xFFFFFFFF;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Verify that the API for integer deployment works for Int32 type and empty deployment.
*/
TEST_F(DeploymentTest, Int32WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    int32_t val1 = (int32_t)0xA55A6996;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    int32_t exp1 = (int32_t)0xFFFFFFFF;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Check that an UInt32 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt32WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 32; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t mask = (uint32_t)(0xFFFFFFFF >> (32 - i));
        uint32_t val1 = (uint32_t)(0xBA987654 & mask);
        CommonAPI::SomeIP::IntegerDeployment<uint32_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[0] << std::endl;
            EXPECT_EQ(data[0], val1 & 0xFF);
        }
        if (length == 2) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[1], val1 & 0xFF);
        }
        if (length == 3) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF0000) >> 16);
            EXPECT_EQ(data[1], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[2], val1 & 0xFF);
        }
        if (length == 4) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF000000) >> 24);
            EXPECT_EQ(data[1], (val1 & 0xFF0000) >> 16);
            EXPECT_EQ(data[2], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[3], val1 & 0xFF);
        }
    }
}
/**
* @test Check that an Int32 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int32WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 32; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint32_t mask = (uint32_t)(0xFFFFFFFF >> (32 - i));
        int32_t val1 = (int32_t)(0xBA987654 & mask);
        CommonAPI::SomeIP::IntegerDeployment<int32_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));
        if (length == 1) {
            // std::cout << std::hex << (uint16_t) i << ": " << (val1 & 0xFF) << " " << (uint16_t) data[0] << std::endl;
            EXPECT_EQ(data[0], val1 & 0xFF);
        }
        if (length == 2) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[1], val1 & 0xFF);
        }
        if (length == 3) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF0000) >> 16);
            EXPECT_EQ(data[1], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[2], val1 & 0xFF);
        }
        if (length == 4) {
            // assuming big-endian on the stream!
            EXPECT_EQ(data[0], (val1 & 0xFF000000) >> 24);
            EXPECT_EQ(data[1], (val1 & 0xFF0000) >> 16);
            EXPECT_EQ(data[2], (val1 & 0xFF00) >> 8);
            EXPECT_EQ(data[3], val1 & 0xFF);
        }
    }
}

/**
* @test Check that an UInt32 data is clipped according to bit length input and output deployments.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt32WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 32; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        uint32_t mask = (uint32_t)(0xFFFFFFFF >> (32 - i));
        uint32_t val1 = (uint32_t)(0xE765FEDC & mask);
        CommonAPI::SomeIP::IntegerDeployment<uint32_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<uint32_t> id(i);
        uint32_t exp1 = 0x0000;
        inStream.readValue(exp1, &id);
        exp1 = exp1 & mask;
        // std::cout << std::hex << (uint16_t) i << ": " << val1 << " " << exp1 << std::endl;

        EXPECT_EQ(val1, exp1);
    }
}
/**
* @test Check that an Int32 data is clipped according to bit length input and output deployments.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int32WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 32; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        uint32_t mask = (uint32_t)(0xFFFFFFFF >> (32 - i));
        int32_t val1 = (int32_t)(0xE765FEDC & mask);
        CommonAPI::SomeIP::IntegerDeployment<int32_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<int32_t> id(i);
        int32_t exp1 = 0x0000;
        inStream.readValue(exp1, &id);
        exp1 = exp1 & mask;
        // std::cout << std::hex << (uint16_t) i << ": " << val1 << " " << exp1 << std::endl;

        EXPECT_EQ(val1, exp1);
    }
}

/**
* @test Verify that the API for integer deployment works for UInt64 type and empty deployment.
*/
TEST_F(DeploymentTest, UInt64WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    uint64_t val1 = 0xA55A6996A55A6996LL;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    uint64_t exp1 = 0xFFFFFFFFFFFFFFFFLL;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Verify that the API for integer deployment works for Int64 type and empty deployment.
*/
TEST_F(DeploymentTest, Int64WithEmptyDeployment) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);

    int64_t val1 = 0xA55A6996A55A6996UL;
    CommonAPI::EmptyDeployment ed;
    outStream.writeValue(val1, &ed);
    outStream.flush();

    CommonAPI::SomeIP::InputStream inStream(message, false);

    int64_t exp1 = 0xFFFFFFFFFFFFFFFFUL;
    inStream.readValue(exp1, &ed);

    EXPECT_EQ(val1, exp1);
}
/**
* @test Check that an UInt64 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt64WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 64; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint64_t mask = (uint64_t)(0xFFFFFFFFFFFFFFFFLL >> (64 - i));
        uint64_t val1 = 0xF0E1D2C3B4A59687LL & mask;
        CommonAPI::SomeIP::IntegerDeployment<uint64_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));

        for (CommonAPI::SomeIP::message_length_t l = 1; l <= length; l++) {
            EXPECT_EQ(data[l - 1], (val1 >> (8 * (length - l))) & 0xFF);
        }
    }
}
/**
* @test Check that an Int64 data is clipped according to bit length output deployment.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int64WithOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 64; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint64_t mask = (uint64_t)(0xFFFFFFFFFFFFFFFFLL >> (64 - i));
        int64_t val1 = 0xF0E1D2C3B4A59687LL & mask;
        CommonAPI::SomeIP::IntegerDeployment<int64_t> id(i);
        outStream.writeValue(val1, &id);
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)((i + 7) / 8));

        for (CommonAPI::SomeIP::message_length_t l = 1; l <= length; l++) {
            EXPECT_EQ(data[l - 1], (val1 >> (8 * (length - l))) & 0xFF);
        }
    }
}

/**
* @test Check that an UInt64 data is clipped according to bit length input and output deployments.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_UInt64WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 1; i <= 64; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint64_t mask = (uint64_t)(0xFFFFFFFFFFFFFFFFLL >> (64 - i));
        uint64_t val1 = 0xF0E1D2C3B4A59687LL & mask;
        CommonAPI::SomeIP::IntegerDeployment<uint64_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<uint64_t> id(i);
        uint64_t exp1 = 0x0000000000000000LL;
        inStream.readValue(exp1, &id);
        EXPECT_EQ(val1, exp1);
    }
}
/**
* @test Check that an Int64 data is clipped according to bit length input and output deployments.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_Int64WithInputAndOutputBitLengthDeployment) {
    CommonAPI::SomeIP::Message message;

    for (uint8_t i = 2; i <= 64; i++) {
        message = CommonAPI::SomeIP::Message::createMethodCall(
            CommonAPI::SomeIP::Address(0, 0, 0, 0),
            515,
            false);
        CommonAPI::SomeIP::OutputStream outStream(message, false);

        uint64_t mask = (uint64_t)(0xFFFFFFFFFFFFFFFFLL >> (64 - i));
        int64_t val1 = 0xF0E1D2C3B4A59687LL & mask;
        CommonAPI::SomeIP::IntegerDeployment<int64_t> od(i);
        outStream.writeValue(val1, &od);
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        CommonAPI::SomeIP::IntegerDeployment<int64_t> id(i);
        int64_t exp1 = 0x0000000000000000LL;
        inStream.readValue(exp1, &id);
        exp1 = exp1 & mask;
        EXPECT_EQ(val1, exp1);
    }
}
/**
* @test Check that an attribute with 8-bit data has its value clipped correctly.
*/
TEST_F(DeploymentTest, AttributeInteger8BitClipping) {

    CommonAPI::CallStatus callStatus;

    uint8_t uint8TestValue = +101;
    int8_t int8TestValue = -101;

    uint8_t uint8ResultValue = 0;
    int8_t int8ResultValue = 0;

    uint8TestValue = 255;
    testProxy_->getAUint8b1Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint8ResultValue, 1);
    uint8TestValue = 254;
    testProxy_->getAUint8b2Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(2, uint8ResultValue);
    uint8TestValue = 253;
    testProxy_->getAUint8b3Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(5, uint8ResultValue);
    uint8TestValue = 252;
    testProxy_->getAUint8b4Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(12, uint8ResultValue);
    uint8TestValue = 251;
    testProxy_->getAUint8b5Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(27, uint8ResultValue);
    uint8TestValue = 250;
    testProxy_->getAUint8b6Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(58, uint8ResultValue);
    uint8TestValue = 249;
    testProxy_->getAUint8b7Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(121, uint8ResultValue);
    uint8TestValue = 248;
    testProxy_->getAUint8b8Attribute().setValue(uint8TestValue, callStatus, uint8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(248, uint8ResultValue);

    // negative signed values
    int8TestValue = -2;
    testProxy_->getAInt8b2Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-2, int8ResultValue);
    int8TestValue = -3;
    testProxy_->getAInt8b3Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-3, int8ResultValue);
    int8TestValue = -4;
    testProxy_->getAInt8b4Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-4, int8ResultValue);
    int8TestValue = -5;
    testProxy_->getAInt8b5Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-5, int8ResultValue);
    int8TestValue = -6;
    testProxy_->getAInt8b6Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-6, int8ResultValue);
    int8TestValue = -7;
    testProxy_->getAInt8b7Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-7, int8ResultValue);
    int8TestValue = -8;
    testProxy_->getAInt8b8Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(-8, int8ResultValue);

    // positive signed values
    int8TestValue = 5;
    testProxy_->getAInt8b2Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(1, int8ResultValue);
    int8TestValue = 10;
    testProxy_->getAInt8b3Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(2, int8ResultValue);
    int8TestValue = 21;
    testProxy_->getAInt8b4Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(5, int8ResultValue);
    int8TestValue = 44;
    testProxy_->getAInt8b5Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(12, int8ResultValue);
    int8TestValue = 91;
    testProxy_->getAInt8b6Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(27, int8ResultValue);
    int8TestValue = 58;
    testProxy_->getAInt8b7Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(58, int8ResultValue);
    int8TestValue = 121;
    testProxy_->getAInt8b8Attribute().setValue(int8TestValue, callStatus, int8ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(121, int8ResultValue);
}
/**
* @test Check that an attribute with 16-bit data has its value clipped correctly.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_AttributeInteger16BitClipping) {

    CommonAPI::CallStatus callStatus;

    uint16_t uint16TestValue = +10101;
    int16_t int16TestValue = -10101;

    uint16_t uint16ResultValue = 0;
    int16_t int16ResultValue = 0;

    uint16TestValue = +10101;
    testProxy_->getAUint16b1Attribute().setValue(uint16TestValue, callStatus, uint16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint16ResultValue, 1);

    uint16TestValue = +10203;
    testProxy_->getAUint16b16Attribute().setValue(uint16TestValue, callStatus, uint16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint16ResultValue, 10203);

    uint16TestValue = +10204;
    testProxy_->getAUint16b9Attribute().setValue(uint16TestValue, callStatus, uint16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint16ResultValue, uint16TestValue & ((1 << 9) - 1));

    // positive signed values
    int16TestValue = +10101;
    testProxy_->getAInt16b2Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, 1);

    int16TestValue = +10102;
    testProxy_->getAInt16b16Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, 10102);

    int16TestValue = +10102;
    testProxy_->getAInt16b7Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, int16TestValue & ((1 << 6) - 1));

    // negative signed values
    int16TestValue = -10101;
    testProxy_->getAInt16b2Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, -1);

    int16TestValue = -10102;
    testProxy_->getAInt16b16Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, -10102);

    int16TestValue = -10102;
    testProxy_->getAInt16b7Attribute().setValue(int16TestValue, callStatus, int16ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int16ResultValue, int16TestValue % (-64));

}

/**
* @test Check that an attribute with 32-bit data has its value clipped correctly.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_AttributeInteger32BitClipping) {

    CommonAPI::CallStatus callStatus;

    uint32_t uint32TestValue = +10101;
    int32_t int32TestValue = -10101;

    uint32_t uint32ResultValue = 0;
    int32_t int32ResultValue = 0;

    uint32TestValue = +101011;
    testProxy_->getAUint32b1Attribute().setValue(uint32TestValue, callStatus, uint32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint32ResultValue, (uint32_t)1);

    uint32TestValue = +1020300;
    testProxy_->getAUint32b32Attribute().setValue(uint32TestValue, callStatus, uint32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint32ResultValue, (uint32_t)1020300);

    uint32TestValue = +10204000;
    testProxy_->getAUint32b12Attribute().setValue(uint32TestValue, callStatus, uint32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint32ResultValue, uint32TestValue & ((1 << 12) - 1));

    // positive signed values
    int32TestValue = +1010101;
    testProxy_->getAInt32b2Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, (int32_t)1);

    int32TestValue = +10102222;
    testProxy_->getAInt32b32Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, (int32_t)10102222);

    int32TestValue = +101023333;
    testProxy_->getAInt32b29Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, int32TestValue & ((1 << 28) - 1));

    // negative signed values
    int32TestValue = -10101;
    testProxy_->getAInt32b2Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, -1);

    int32TestValue = -101020;
    testProxy_->getAInt32b32Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, -101020);

    int32TestValue = -10102000;
    testProxy_->getAInt32b29Attribute().setValue(int32TestValue, callStatus, int32ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int32ResultValue, int32TestValue % (-(1<<29)));

}
/**
* @test Check that an attribute with 64-bit data has its value clipped correctly.
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_AttributeInteger64BitClipping) {

    CommonAPI::CallStatus callStatus;

    uint64_t uint64TestValue = +10101;
    int64_t int64TestValue = -10101;

    uint64_t uint64ResultValue = 0;
    int64_t int64ResultValue = 0;

    uint64TestValue = +101011123412341LL;
    testProxy_->getAUint64b1Attribute().setValue(uint64TestValue, callStatus, uint64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint64ResultValue, (uint64_t)1);

    uint64TestValue = +101011123412341LL;
    testProxy_->getAUint64b64Attribute().setValue(uint64TestValue, callStatus, uint64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint64ResultValue, (uint64_t)101011123412341LL);

    uint64TestValue = +101011123412341LL;
    testProxy_->getAUint64b44Attribute().setValue(uint64TestValue, callStatus, uint64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(uint64ResultValue, uint64TestValue & ((1LL << 44) - 1));

    // positive signed values
    int64TestValue = +101011123412341LL;
    testProxy_->getAInt64b2Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, (int64_t)1LL);

    int64TestValue = +101011123412341LL;
    testProxy_->getAInt64b64Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, (int64_t)101011123412341LL);

    int64TestValue = +101011123412341LL;
    testProxy_->getAInt64b62Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, int64TestValue & ((1LL << 61) - 1));

    // negative signed values
    int64TestValue = -101011123412341LL;
    testProxy_->getAInt64b2Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, -1LL);

    int64TestValue = -101011123412341LL;
    testProxy_->getAInt64b64Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, -101011123412341LL);

    int64TestValue = -101011123412341LL;
    testProxy_->getAInt64b62Attribute().setValue(int64TestValue, callStatus, int64ResultValue);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(int64ResultValue, int64TestValue % (-(1LL<<62)));
}
/**
* @test Check that an UInt8 data is clipped according to bit length input and output deployments.
*/
TEST_F(DeploymentTest, PackTwoFourBitIntegersToOneByte) {
    CommonAPI::SomeIP::Message message;

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    CommonAPI::SomeIP::OutputStream outStream(message, false);
    uint8_t val1 = 0x04;
    CommonAPI::SomeIP::IntegerDeployment<uint8_t> od(4);
    outStream.writeValue(val1, &od);
    uint8_t val2 = 0x0C;
    outStream.writeValue(val2, &od);
    outStream.flush();

    CommonAPI::SomeIP::byte_t * data = message.getBodyData();
    CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
    EXPECT_EQ(length, (CommonAPI::SomeIP::message_length_t)1);
    EXPECT_EQ(data[0], 0xC4);
}
/**
* @test Check ranged integers with values in the specified range
*/
TEST_F(DeploymentTest, RangedIntegersInRange) {

    CommonAPI::CallStatus callStatus;
    int32_t testInteger;
    CommonAPI::RangedInteger<0,1> testIntegerResult1;
    CommonAPI::RangedInteger<-5,5> testIntegerResult2;
    CommonAPI::RangedInteger<-5000000,5000000> testIntegerResult3;

    testInteger = 0;
    testProxy_->getAInt0to1Attribute().setValue(testInteger, callStatus, testIntegerResult1);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult1, 0);

    testInteger = 1;
    testProxy_->getAInt0to1Attribute().setValue(testInteger, callStatus, testIntegerResult1);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult1, 1);

    testInteger = -5;
    testProxy_->getAIntm5to5Attribute().setValue(testInteger, callStatus, testIntegerResult2);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult2, -5);

    testInteger = 5;
    testProxy_->getAIntm5to5Attribute().setValue(testInteger, callStatus, testIntegerResult2);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult2, 5);

    testInteger = 5000000;
    testProxy_->getAIntm5mto5mAttribute().setValue(testInteger, callStatus, testIntegerResult3);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult3, 5000000);

    testInteger = -5000000;
    testProxy_->getAIntm5mto5mAttribute().setValue(testInteger, callStatus, testIntegerResult3);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(testIntegerResult3, -5000000);

}

/**
* @test Check ranged integers with values outside the specified range
*/
TEST_F(DeploymentTest, RangedIntegersOutOfRange) {

    CommonAPI::CallStatus callStatus;
    int32_t testInteger;
    CommonAPI::RangedInteger<0,1> testIntegerResult1;
    CommonAPI::RangedInteger<-5,5> testIntegerResult2;
    CommonAPI::RangedInteger<-5000000,5000000> testIntegerResult3;

    testInteger = -1;
    testProxy_->getAInt0to1Attribute().setValue(testInteger, callStatus, testIntegerResult1);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

    testInteger = 2;
    testProxy_->getAInt0to1Attribute().setValue(testInteger, callStatus, testIntegerResult1);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

    testInteger = -6;
    testProxy_->getAIntm5to5Attribute().setValue(testInteger, callStatus, testIntegerResult2);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

    testInteger = 6;
    testProxy_->getAIntm5to5Attribute().setValue(testInteger, callStatus, testIntegerResult2);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

    testInteger = 5000001;
    testProxy_->getAIntm5mto5mAttribute().setValue(testInteger, callStatus, testIntegerResult3);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);

    testInteger = -5000001;
    testProxy_->getAIntm5mto5mAttribute().setValue(testInteger, callStatus, testIntegerResult3);
    ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
}

/**
* @test Check that an attribute with ranged integer data has its value clipped correctly.
* Disabled until bit clipping works.
*/
TEST_F(DeploymentTest, DISABLED_RangedIntegerClipping) {

    CommonAPI::CallStatus callStatus;

    int testValue = 5;
    CommonAPI::RangedInteger<-5, 5> testResult;

    testProxy_->getAIntm5to5b3Attribute().setValue(testValue, callStatus, testResult);
    ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
