/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <iostream>

#ifndef _WIN32
#include <unistd.h>
#endif

#include <CommonAPI/CommonAPI.hpp>
#include <CommonAPI/Extensions/AttributeCacheExtension.hpp>
#include <v1/commonapi/examples/B/MergedInterfaceBProxy.hpp>

using namespace v1::commonapi::examples::B;

void recv_cb(const CommonAPI::CallStatus& callStatus, const int32_t& val) {
    std::cout << "Receive callback: " << val << std::endl;
}

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E02CB");
    CommonAPI::Runtime::setProperty("LogApplication", "E02CB");
    CommonAPI::Runtime::setProperty("LibraryBase", "MergedInterface-B");

    std::shared_ptr < CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.examples.B.MergedInterfaceB";
    std::string connection = "client-sample";

    auto myProxy = runtime->buildProxyWithDefaultAttributeExtension<MergedInterfaceBProxy, CommonAPI::Extensions::AttributeCacheExtension>(domain, instance, connection);

    std::cout << "Waiting for service to become available." << std::endl;
    while (!myProxy->isAvailable()) {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
    }

    CommonAPI::CallStatus callStatus;

    int32_t value = 0;

    CommonAPI::CallInfo info(1000);
    info.sender_ = 5678;

    // Get actual attribute value from service
    std::cout << "Proxy B getting attribute X3 value: " << value << std::endl;
    myProxy->getX3Attribute().getValue(callStatus, value, &info);
    if (callStatus != CommonAPI::CallStatus::SUCCESS) {
        std::cerr << "Remote call A failed!\n";
        return -1;
    }
    std::cout << "Proxy B got attribute X3 value: " << value << std::endl;

    // Subscribe for receiving values
    myProxy->getX3Attribute().getChangedEvent().subscribe([&](const int32_t& val) {
        std::cout << "Proxy B received attrbiute X3 change message: " << val << std::endl;
    });

    value = 100;

    // Asynchronous call to set attribute of service
    std::function<void(const CommonAPI::CallStatus&, int32_t)> fcb = recv_cb;
    myProxy->getX3Attribute().setValueAsync(value, fcb, &info);

    while (true) {
        int32_t errorValue = -1;
        int32_t valueCached = *myProxy->getX3AttributeExtension().getCachedValue(errorValue);
        if (valueCached != errorValue) {
            std::cout << "Proxy B got cached attribute X3 value[" << (int)valueCached << "]: " << valueCached << std::endl;
        } else {
            std::cout << "Proxy B got cached attribute X3 error value[" << (int)valueCached << "]: " << valueCached << std::endl;
        }
        std::this_thread::sleep_for(std::chrono::microseconds(1000000));
    }
}
