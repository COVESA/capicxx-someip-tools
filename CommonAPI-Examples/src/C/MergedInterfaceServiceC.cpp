/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include <thread>
#include <iostream>

#include <CommonAPI/CommonAPI.hpp>
#include "MergedInterfaceStubImplC.hpp"

int main() {
    CommonAPI::Runtime::setProperty("LogContext", "E02SC");
    CommonAPI::Runtime::setProperty("LogApplication", "E02SC");
    CommonAPI::Runtime::setProperty("LibraryBase", "MergedInterface-C");

    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();

    std::string domain = "local";
    std::string instance = "commonapi.examples.C.MergedInterfaceC";
    std::string connection = "service-sample";

    std::shared_ptr<MergedInterfaceStubImplC> myService = std::make_shared<MergedInterfaceStubImplC>();
    while (!runtime->registerService(domain, instance, myService, connection)) {
        std::cout << "Register Service C failed, trying again in 100 milliseconds..." << std::endl;
        std::this_thread::sleep_for(std::chrono::milliseconds(100));
    }

    std::cout << "Successfully Registered Service C!" << std::endl;

    while (true) {
        myService->incCounter(); // Change value of attribute, see stub implementation
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(2));
    }
    return 0;
}
