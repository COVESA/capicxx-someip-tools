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
void DeploymentTestStub::mArrayi8_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::i8Array _inArg, mArrayi8_ioReply_t _reply) {
    (void)_client;

    length_ = (uint8_t)_inArg[0];

    std::vector<int8_t> outArray(length_);
    std::iota (std::begin(outArray), std::end(outArray), length_);
    _reply(outArray);
}

void DeploymentTestStub::mArrayi8_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::i8Array _inArg, mArrayi8_iReply_t _reply) {
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

// map test methods
void DeploymentTestStub::mMap_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_ioReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    TestInterface::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert( {{i, "return"}});
    }
    _reply(outArg);
}

void DeploymentTestStub::mMap_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_iReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    _reply();
}

void DeploymentTestStub::mMap_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_oReply_t _reply) {
    (void)_client;
    TestInterface::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert( {{i, "return"}});
    }
    _reply(outArg);
}
void DeploymentTestStub::mMap_n5_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_n5_ioReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    TestInterface::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert( {{i, "return"}});
    }
    _reply(outArg);
}

void DeploymentTestStub::mMap_n6_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_n6_iReply_t _reply) {
    (void)_client;
    auto lengthstring = _inArg.find(0);
    if (lengthstring != _inArg.end()) {
        length_ = std::stoi(lengthstring->second);
    }
    _reply();
}

void DeploymentTestStub::mMap_n7_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_n7_oReply_t _reply) {
    (void)_client;
    TestInterface::tMapString outArg;
    for (uint32_t i = 0; i < length_; i++) {
        outArg.insert( {{i, "return"}});
    }
    _reply(outArg);
}

} /* namespace deploymenttest */
} /* namespace someip */
} /* namespace commonapi */
} /* namespave v1 */
