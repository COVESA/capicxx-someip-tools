/* Copyright (C) 2017 BMW Group
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef DEPLOYMENTTESTSTUB_H_
#define DEPLOYMENTTESTSTUB_H_

#include "v1/commonapi/someip/deploymenttest/TestInterfaceStubDefault.hpp"

namespace v1 {
namespace commonapi {
namespace someip {
namespace deploymenttest {

class DeploymentTestStub : public v1_0::commonapi::someip::deploymenttest::TestInterfaceStubDefault {
public:
    DeploymentTestStub();
    virtual ~DeploymentTestStub();

    COMMONAPI_EXPORT virtual void mArrayi8_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::i8Array _inArg, mArrayi8_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mArrayi8_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::i8Array _inArg, mArrayi8_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mArrayi8_o(const std::shared_ptr<CommonAPI::ClientId> _client, mArrayi8_oReply_t _reply);

    COMMONAPI_EXPORT virtual void mMap_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_oReply_t _reply);

    COMMONAPI_EXPORT virtual void mMap_n5_io(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_n5_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_n6_i(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tMapString _inArg, mMap_n6_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_n7_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_n7_oReply_t _reply);

private:
    uint32_t length_;

};

} /* namespace deploymenttest */
} /* namespace someip */
} /* namespace commonapi */
} /* namespave v1 */

#endif /* DEPLOYMENTTESTSTUB_H_ */
