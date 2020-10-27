/* Copyright (C) 2017-2020 BMW Group
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

    COMMONAPI_EXPORT virtual void mArrayi8_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::i8Array _inArg, mArrayi8_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mArrayi8_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::i8Array _inArg, mArrayi8_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mArrayi8_o(const std::shared_ptr<CommonAPI::ClientId> _client, mArrayi8_oReply_t _reply);
    COMMONAPI_EXPORT virtual void mArray_anon_io(const std::shared_ptr<CommonAPI::ClientId> _client, std::vector< int8_t > _inArg, mArray_anon_ioReply_t _reply);

    COMMONAPI_EXPORT virtual void mMap_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_oReply_t _reply);

    COMMONAPI_EXPORT virtual void mMap_n5_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_n5_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_n6_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tMapString _inArg, mMap_n6_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mMap_n7_o(const std::shared_ptr<CommonAPI::ClientId> _client, mMap_n7_oReply_t _reply);

    COMMONAPI_EXPORT virtual void mUnion_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 _inArg, mUnion_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mUnion_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tUnion_d2 _inArg, mUnion_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mUnion_o(const std::shared_ptr<CommonAPI::ClientId> _client, mUnion_oReply_t _reply);
    COMMONAPI_EXPORT virtual void mUnion_of(const std::shared_ptr<CommonAPI::ClientId> _client, mUnion_ofReply_t _reply);

    COMMONAPI_EXPORT virtual void mStruct_io(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg _inArg, mStruct_ioReply_t _reply);
    COMMONAPI_EXPORT virtual void mStruct_i(const std::shared_ptr<CommonAPI::ClientId> _client, @TYPE_COLLECTION_BASE_NAME@::tStruct_w2_arg _inArg, mStruct_iReply_t _reply);
    COMMONAPI_EXPORT virtual void mStruct_o(const std::shared_ptr<CommonAPI::ClientId> _client, mStruct_oReply_t _reply);
    COMMONAPI_EXPORT virtual void mStruct_of(const std::shared_ptr<CommonAPI::ClientId> _client, mStruct_oReply_t _reply);

    COMMONAPI_EXPORT virtual void mBCastTrigger(const std::shared_ptr<CommonAPI::ClientId> _client, TestInterface::tEnumTriggerType _type, uint32_t _parameter, mBCastTriggerReply_t _reply);


private:
    uint32_t length_;

};

} /* namespace deploymenttest */
} /* namespace someip */
} /* namespace commonapi */
} /* namespave v1 */

#endif /* DEPLOYMENTTESTSTUB_H_ */
