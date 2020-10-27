/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/**
* @file SomeIPStructDeploymentTest
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
* @test Verify that the API for struct deployments works
*/
TEST_F(DeploymentTest, StructWithDeployment) {
    CommonAPI::SomeIP::Message message;
    CommonAPI::SomeIP::StructDeployment<
        CommonAPI::EmptyDeployment,
        CommonAPI::SomeIP::IntegerDeployment<uint8_t>
    > ed_0(0, nullptr, nullptr);
    CommonAPI::SomeIP::StructDeployment<
        CommonAPI::EmptyDeployment,
        CommonAPI::SomeIP::IntegerDeployment<uint8_t>
    > ed_1(1, nullptr, nullptr);
    CommonAPI::SomeIP::StructDeployment<
        CommonAPI::EmptyDeployment,
        CommonAPI::SomeIP::IntegerDeployment<uint8_t>
    > ed_2(2, nullptr, nullptr);
    CommonAPI::SomeIP::StructDeployment<
        CommonAPI::EmptyDeployment,
        CommonAPI::SomeIP::IntegerDeployment<uint8_t>
    > ed_4(4, nullptr, nullptr);

    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);

        outStream.writeValue(outv, &ed_0);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 inv;

        inStream.readValue(inv, &ed_0);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);

        outStream.writeValue(outv, &ed_1);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 inv;

        inStream.readValue(inv, &ed_1);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);

        outStream.writeValue(outv, &ed_2);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 inv;

        inStream.readValue(inv, &ed_2);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
    {
        CommonAPI::SomeIP::OutputStream outStream(message, false);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);

        outStream.writeValue(outv, &ed_4);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::InputStream inStream(message, false);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 inv;

        inStream.readValue(inv, &ed_4);
        EXPECT_FALSE(inStream.hasError());
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Stream some struct data with various deployments.
*/
TEST_F(DeploymentTest, StructWithOutputDeployment) {
    CommonAPI::SomeIP::Message message;
    message = CommonAPI::SomeIP::Message::createMethodCall(
        CommonAPI::SomeIP::Address(0, 0, 0, 0),
        515,
        false);
    {
        CommonAPI::SomeIP::StructDeployment<
            CommonAPI::EmptyDeployment,
            CommonAPI::SomeIP::IntegerDeployment<uint8_t>
        > ed(4, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            0, 0, 0, 2, /* = length of data in bytes - four bytes specified in the deployment */
            1, /* true */
            100 /* 100 */
        };

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);
        outStream.writeValue(outv, &ed);
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
        CommonAPI::SomeIP::StructDeployment<
            CommonAPI::EmptyDeployment,
            CommonAPI::SomeIP::IntegerDeployment<uint8_t>
        > ed(2, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            0, 2, /* = length of data in bytes - two bytes specified in the deployment */
            1, /* true */
            100 /* 100 */
        };

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);
        outStream.writeValue(outv, &ed);
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
        CommonAPI::SomeIP::StructDeployment<
            CommonAPI::EmptyDeployment,
            CommonAPI::SomeIP::IntegerDeployment<uint8_t>
        > ed(1, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            2, /* = length of data in bytes - one byte specified in the deployment */
            1, /* true */
            100 /* 100 */
        };

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);
        outStream.writeValue(outv, &ed);
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
        CommonAPI::SomeIP::StructDeployment<
            CommonAPI::EmptyDeployment,
            CommonAPI::SomeIP::IntegerDeployment<uint8_t>
        > ed(0, nullptr, nullptr);

        CommonAPI::SomeIP::OutputStream outStream(message, false);

        CommonAPI::SomeIP::byte_t expected_data[] = {
            1, /* true */
            100 /* 100 */
        };

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);
        outStream.writeValue(outv, &ed);
        EXPECT_FALSE(outStream.hasError());
        outStream.flush();

        CommonAPI::SomeIP::byte_t * data = message.getBodyData();
        CommonAPI::SomeIP::message_length_t length = message.getBodyLength();
        ASSERT_EQ(sizeof expected_data, length);
        for (unsigned int i = 0; i < length; i++) {
            EXPECT_EQ(expected_data[i], data[i]);
        }
    }
}
/**
* @test Pass an attribute with struct type data.
*/
TEST_F(DeploymentTest, StructAttributeDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_wd outv(true, 100);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_wd inv;

        testProxy_->getAStruct_wd_attrAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_long outv;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_long inv;

        outv.setBooleanMember(true);
        std::vector<int8_t> a(200);
        outv.setArrayMember(a);

        testProxy_->getAStruct_longAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Pass an attribute with struct type data, with too long a value to fit in LengthWidth deployment.
*/
TEST_F(DeploymentTest, StructTooShortArrayLengthWidth) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_long outv;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_long inv;

        outv.setBooleanMember(true);
        std::vector<int8_t> a(200000);
        outv.setArrayMember(a);

        testProxy_->getAStruct_longAttribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Pass an attribute with struct type deployment.
*/
TEST_F(DeploymentTest, StructTypeDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w0 outv;
        outv.setBooleanMember(true);
        std::vector<int8_t> a(2000);
        outv.setArrayMember(a);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w0 inv;

        testProxy_->getAStruct_w0Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 outv;
        outv.setBooleanMember(true);
        std::vector<int8_t> a(200);
        outv.setArrayMember(a);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 inv;

        testProxy_->getAStruct_w1Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 outv;
        outv.setBooleanMember(false);
        std::vector<int8_t> a(2000);
        outv.setArrayMember(a);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 inv;

        testProxy_->getAStruct_w1Attribute().setValue(outv, callStatus, inv);
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w2 outv(true, 100);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w2 inv;

        testProxy_->getAStruct_w2Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 outv(true, 100);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w4 inv;

        testProxy_->getAStruct_w4Attribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Check that an attribute struct deployment overrides a type deployment.
*/
TEST_F(DeploymentTest, StructAttrDeplOverridesTypeDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w0 outv;
        outv.setBooleanMember(true);
        std::vector<int8_t> a(2000);
        outv.setArrayMember(a);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_w0 inv;

        testProxy_->getAStruct_w0_overrideAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment won't allow to fit such a long value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify deployments of struct fields.
*/
TEST_F(DeploymentTest, StructAttrFieldDeploymentsOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setArrayMember(a);

        std::string v1("abcd");
        unionMember = v1;
        outv.setUnionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls inv;

        testProxy_->getAStruct_field_type_deplsAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify deployments of struct fields. Use an invalid union member.
*/
// This case tests that the union member has the deployment set up correctly.
// It sets up a value that should be invalid, according to the union deployment.
// If the union field member deployment is missing, the setting of the attribute would succeed.
TEST_F(DeploymentTest, StructAttrFieldDeploymentsFaultyUnionMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setArrayMember(a);

        std::string v1("abcde"); // this is the wrong length and should fail.
        unionMember = v1;
        outv.setUnionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls inv;

        testProxy_->getAStruct_field_type_deplsAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the union member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify deployments of struct fields. Use an invalid array member.
*/
TEST_F(DeploymentTest, StructAttrFieldDeploymentsFaultyArrayMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(2000);
        outv.setArrayMember(a);

        std::string v1("abcd"); // this is the corrent value.
        unionMember = v1;
        outv.setUnionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls inv;

        testProxy_->getAStruct_field_type_deplsAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the array member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify deployments of struct fields. Use an invalid struct member.
*/
TEST_F(DeploymentTest, StructAttrFieldDeploymentsFaultyStructMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setArrayMember(a);

        std::string v1("abcd"); // this is the corrent value.
        unionMember = v1;
        outv.setUnionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(2000);
        structMember.setArrayMember(a8);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_type_depls inv;

        testProxy_->getAStruct_field_type_deplsAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the struct member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify field deployments of an extended structure.
*/
TEST_F(DeploymentTest, ExtendedStructAttrFieldDeploymentsOK) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStructExtended outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setEarrayMember(a);

        std::string v1("abcd");
        unionMember = v1;
        outv.setEunionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setEstructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStructExtended inv;

        testProxy_->getAStructExtendedAttribute().setValue(outv, callStatus, inv);
        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify field deployments of an extended structure. Use a faulty union member.
*/
TEST_F(DeploymentTest, ExtendedStructAttrFieldDeploymentsFaultyUnionMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStructExtended outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setEarrayMember(a);

        std::string v1("abcde"); // this is the wrong length and should fail.
        unionMember = v1;
        outv.setEunionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setEstructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStructExtended inv;

        testProxy_->getAStructExtendedAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the union member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify field deployments of an extended structure. Use a faulty array member.
*/
TEST_F(DeploymentTest, ExtendedStructAttrFieldDeploymentsFaultyArrayMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStructExtended outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(2000);
        outv.setEarrayMember(a);

        std::string v1("abcd"); // this is the corrent value.
        unionMember = v1;
        outv.setEunionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(20);
        structMember.setArrayMember(a8);
        outv.setEstructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStructExtended inv;

        testProxy_->getAStructExtendedAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the array member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify field deployments of an extended structure. Use a faulty struct member.
*/
TEST_F(DeploymentTest, ExtendedStructAttrFieldDeploymentsFaultyStructMember) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStructExtended outv;

        @TYPE_COLLECTION_FULL_NAME@::tUnion_d3 unionMember;
        @TYPE_COLLECTION_FULL_NAME@::tStruct_w1 structMember;

        std::vector<int16_t> a(20);
        outv.setEarrayMember(a);

        std::string v1("abcd"); // this is the corrent value.
        unionMember = v1;
        outv.setEunionMember(unionMember);

        structMember.setBooleanMember(true);
        std::vector<int8_t> a8(2000);
        structMember.setArrayMember(a8);
        outv.setEstructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tStructExtended inv;

        testProxy_->getAStructExtendedAttribute().setValue(outv, callStatus, inv);
        // will fail because the deployment of the struct member prohibits the value
        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStruct...') work in general.
*/
TEST_F(DeploymentTest, StructFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 0x0FFF;
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv.setUnionMember(unionMember);

        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        EXPECT_EQ(outv, inv);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStructStruct...')
*/
TEST_F(DeploymentTest, StructStructFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        // this value is too large, and the value should not be transmitted.
        std::vector<uint8_t> a(257);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 3;
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv.setUnionMember(unionMember);

        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStructArray...')
*/
TEST_F(DeploymentTest, StructArrayFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 3;
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv.setUnionMember(unionMember);

        // this value is too large, and the value should not be transmitted.
        std::vector<int8_t> arrayMember(80);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStructUnion...')
*/
TEST_F(DeploymentTest, StructUnionFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 3;
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        // this value is too large, and the value should not be transmitted.
        std::string str(70000, 'a');
        unionMember = str;
        outv.setUnionMember(unionMember);

        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_NE(callStatus, CommonAPI::CallStatus::SUCCESS);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStructInt...')
* Disabled until the bit length deployments are working again.
*/
TEST_F(DeploymentTest, DISABLED_StructIntFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V1;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 4; // this value will be truncated during transfer.
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv.setUnionMember(unionMember);

        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        ASSERT_EQ(inv.getIntMember(), 0);
    }
}
/**
* @test Verify structure field deployments ('SomeIpStructEnum...')
*/
TEST_F(DeploymentTest, StructEnumFieldDeployment) {
    CommonAPI::CallStatus callStatus;
    {
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls outv;

        @TYPE_COLLECTION_FULL_NAME@::tStruct_field structMember;
        std::vector<uint8_t> a(8);
        std::iota (std::begin(a), std::end(a), 0);
        structMember.setUint8Member(a);
        outv.setStructMember(structMember);

        @TYPE_COLLECTION_FULL_NAME@::tEnum enumMember;
        // this enum value is too large to fit. It will be truncated during transfer.
        enumMember = @TYPE_COLLECTION_FULL_NAME@::tEnum::V3;
        outv.setEnumMember(enumMember);

        uint16_t intMember;
        intMember = 3;
        outv.setIntMember(intMember);

        @TYPE_COLLECTION_FULL_NAME@::tUnion_field unionMember;
        std::string str = "str";
        unionMember = str;
        outv.setUnionMember(unionMember);

        std::vector<int8_t> arrayMember(8);
        std::iota (std::begin(arrayMember), std::end(arrayMember), 0);
        outv.setArrayMember(arrayMember);
        @TYPE_COLLECTION_FULL_NAME@::tStruct_field_depls inv;
        testProxy_->getAStruct_field_deplsAttribute().setValue(outv, callStatus, inv);

        ASSERT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
        ASSERT_EQ(inv.getEnumMember(), 232); // 232 is the 8-bit truncated value of V3 = 1000
    }
}

/**
* @test Use a method with an structure as an argument. for both input and output.
*/
TEST_F(DeploymentTest, StructMethodDeployment_IO) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg outv;
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg inv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(200);
    outv.setArrayMember(a);

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_io(outv, callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(outv, inv);
}
TEST_F(DeploymentTest, StructMethodDeployment_I) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg outv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(200);
    outv.setArrayMember(a);

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_i(outv, callStatus);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);

}
TEST_F(DeploymentTest, StructMethodDeployment_O) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg outv;
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg inv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(200);
    outv.setArrayMember(a);

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_o(callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SUCCESS);
    EXPECT_EQ(outv, inv);
}
TEST_F(DeploymentTest, StructMethodDeployment_IO_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg outv;
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg inv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(400);
    outv.setArrayMember(a);

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_io(outv, callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SERIALIZATION_ERROR);
}
TEST_F(DeploymentTest, StructMethodDeployment_I_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg outv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(400);
    outv.setArrayMember(a);

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_i(outv, callStatus);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::SERIALIZATION_ERROR);

}
TEST_F(DeploymentTest, StructMethodDeployment_O_Fail) {
    @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg inv;

    CommonAPI::CallStatus callStatus;
    testProxy_->mStruct_of(callStatus, inv);

    EXPECT_EQ(callStatus, CommonAPI::CallStatus::REMOTE_ERROR);
}

/**
* @test Use a broadcast with a structure.
*/
TEST_F(DeploymentTest, StructBroadcastDeployment) {

    CommonAPI::CallStatus callStatus;
    std::promise<@TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBStructEvent().subscribe([&](
        const @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_STRUCT, 200, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::ready);
    testProxy_->getBUnionEvent().unsubscribe(subscription);
}

/**
* @test Use a broadcast with a structure. Will fail on purpose.
*/
TEST_F(DeploymentTest, StructBroadcastDeploymentBadValue) {

    CommonAPI::CallStatus callStatus;
    std::promise<@TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg> p;
    auto f = p.get_future();

    // subscribe
    uint32_t subscription = testProxy_->getBStructEvent().subscribe([&](
        const @TYPE_COLLECTION_FULL_NAME@::tStruct_w2_arg &y
    ) {
        p.set_value(y);
    });

    // trigger the event
    testProxy_->mBCastTrigger(v1_0::commonapi::someip::deploymenttest::TestInterface::tEnumTriggerType::T_STRUCT, 400, callStatus);
    // wait until broadcast has been signaled
    std::future_status status = f.wait_for(std::chrono::seconds(7));
    EXPECT_EQ(status, std::future_status::timeout);
    testProxy_->getBStructEvent().unsubscribe(subscription);
}

int main(int argc, char** argv) {
    ::testing::InitGoogleTest(&argc, argv);
    ::testing::AddGlobalTestEnvironment(new Environment());
    return RUN_ALL_TESTS();
}
