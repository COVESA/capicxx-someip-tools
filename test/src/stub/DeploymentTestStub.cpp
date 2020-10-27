/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <numeric>

#include "DeploymentTestStub.h"

namespace v1 {
namespace commonapi {
namespace someip {
namespace deploymenttest {

DeploymentTestStub::DeploymentTestStub() {
    length_ = 80;
}

DeploymentTestStub::~DeploymentTestStub() {
}

// array test methods
void DeploymentTestStub::mArrayi8_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::i8Array _inArg, mArrayi8_ioReply_t _reply) {
    (void)_client;

    length_ = (uint8_t)_inArg[0];

    std::vector<int8_t> outArray(length_);
    std::iota (std::begin(outArray), std::end(outArray), length_);
    _reply(outArray);
}

void DeploymentTestStub::mArrayi8_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::i8Array _inArg, mArrayi8_iReply_t _reply) {
    (void)_client;
    length_ = (uint8_t)_inArg[0];
    _reply();
}

void DeploymentTestStub::mArrayi8_o(const std::shared_ptr<CommonAPI::ClientId> _client, mArrayi8_oReply_t _reply) {
    (void)_client;
    std::vector<int8_t> outArray(length_);
    std::iota (std::begin(outArray), std::end(outArray), length_);
    _reply(outArray);
}

void DeploymentTestStub::mArray_anon_io(const std::shared_ptr<CommonAPI::ClientId> _client, std::vector< int8_t > _inArg, mArray_anon_ioReply_t _reply) {
    (void)_client;

    length_ = (uint8_t)_inArg[0];

    std::vector<int8_t> outArray(length_);
    std::iota (std::begin(outArray), std::end(outArray), length_);
    _reply(outArray);
}

// map test methods
void DeploymentTestStub::mMap_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_ioReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    @TYPE_COLLECTION_BASE_NAME@::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert(std::pair<uint32_t, std::string>(i, "return"));
    }
    _reply(outArg);
}

void DeploymentTestStub::mMap_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_iReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    _reply();
}

void DeploymentTestStub::mMap_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_oReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert(std::pair<uint32_t, std::string>(i, "return"));
    }
    _reply(outArg);
}
void DeploymentTestStub::mMap_n5_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_n5_ioReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    @TYPE_COLLECTION_BASE_NAME@::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert(std::pair<uint32_t, std::string>(i, "return"));
    }
    _reply(outArg);
}

void DeploymentTestStub::mMap_n6_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_n6_iReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    _reply();
}

void DeploymentTestStub::mMap_n7_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_n7_oReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert(std::pair<uint32_t, std::string>(i, "return"));
    }
    _reply(outArg);
}

// union test methods
void DeploymentTestStub::mUnion_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 _inArg, mUnion_ioReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 outv;

    outv = _inArg;

    _reply(outv);
}
void DeploymentTestStub::mUnion_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 _inArg, mUnion_iReply_t _reply) {
    (void)_client;
    (void) _inArg;
    _reply();
}
void DeploymentTestStub::mUnion_o(const std::shared_ptr<CommonAPI::ClientId> _client, mUnion_oReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 outv;

    std::string str(492, 'a');
    outv = str;

    _reply(outv);
}
void DeploymentTestStub::mUnion_of(const std::shared_ptr<CommonAPI::ClientId> _client, mUnion_ofReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 outv;

    std::string str(600, 'a');
    outv = str;

    _reply(outv);
}

// struct test methods
void DeploymentTestStub::mStruct_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg _inArg, mStruct_ioReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg outv;

    outv = _inArg;

    _reply(outv);
}
void DeploymentTestStub::mStruct_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg _inArg, mStruct_iReply_t _reply) {
    (void)_client;
    (void) _inArg;
    _reply();
}
void DeploymentTestStub::mStruct_o(const std::shared_ptr<CommonAPI::ClientId> _client, mStruct_oReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg outv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(200);
    outv.setArrayMember(a);

    _reply(outv);
}
void DeploymentTestStub::mStruct_of(const std::shared_ptr<CommonAPI::ClientId> _client, mStruct_ofReply_t _reply) {
    (void)_client;
    @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg outv;

    outv.setBooleanMember(true);
    std::vector<int8_t> a(300);
    outv.setArrayMember(a);

    _reply(outv);
}

void DeploymentTestStub::mBCastTrigger(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tEnumTriggerType _type, uint32_t _parameter, mBCastTriggerReply_t _reply) {
    (void)_client;
    switch (_type) {
    case TestInterface::tEnumTriggerType::T_ARRAY:
        {
            std::vector<int8_t> outArray(_parameter);
            std::iota (std::begin(outArray), std::end(outArray), 0);
            fireBArrayi8Event(outArray);
        }
        break;
    case TestInterface::tEnumTriggerType::T_MAP:
        {

            std::unordered_map<uint32_t, std::string> outMap;
            for (uint32_t i = 0; i < _parameter; i++) {
                outMap.insert(std::pair<uint32_t, std::string>(i, "in"));
            }
            fireBMapEvent(outMap);
        }
        break;
    case TestInterface::tEnumTriggerType::T_UNION:
        {
            @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 outv;
            std::string str(_parameter, 'a');
            outv = str;
            fireBUnionEvent(outv);
        }
        break;
    case TestInterface::tEnumTriggerType::T_STRUCT:
        {
            @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg outv;
            outv.setBooleanMember(true);
            std::vector<int8_t> a(_parameter);
            outv.setArrayMember(a);
            fireBStructEvent(outv);
        }
        break;
    case TestInterface::tEnumTriggerType::T_ANON:
        {
            std::vector<int8_t> outArray(_parameter);
            std::iota (std::begin(outArray), std::end(outArray), 0);
            fireBArray_anonEvent(outArray);
        }
        break;
    default:
        break;
    }

    _reply();

}

} /* namespace deploymenttest */
} /* namespace someip */
} /* namespace commonapi */
} /* namespave v1 */
