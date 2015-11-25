#include <iostream>
#include <iomanip>
#include <dlfcn.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/someip/attrProxy.hpp>

using namespace v1::commonapi::someip;

void recv_cb(const CommonAPI::CallStatus& callStatus, const int32_t& val) {
    std::cout << "Got attribute value callback: " << std::dec << val << std::endl;
}

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();
    std::shared_ptr<attrProxyDefault> myProxy
        = runtime->buildProxy<attrProxy>("local", "BMW.ATM");

    if (myProxy != nullptr) {
        myProxy->isAvailableBlocking();

        // Subscribe for receiving values
        myProxy->getXAttribute().getChangedEvent().subscribe([&](const int32_t& val) {
            std::cout << "Received change message: " << std::dec << val << std::endl;
        });

        CommonAPI::CallStatus callStatus;
        int32_t value = 0;
        int32_t i = 1;

        std::function<void(const CommonAPI::CallStatus&, int32_t)> fcb = recv_cb;
        myProxy->getXAttribute().setValueAsync(1000 * i, fcb);

        //std::this_thread::sleep_for(std::chrono::seconds(2));

        while (true) {
            // Get actual attribute value from service
            myProxy->getXAttribute().getValue(callStatus, value);

            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call getValue failed!\n";
                return -1;
            }

            std::cout << "Got attribute value: " << std::dec << value << std::endl;

            // Asynchronous call to get attribute of service
            std::function<void(const CommonAPI::CallStatus&, int32_t)> fcb = recv_cb;
            myProxy->getXAttribute().getValueAsync(fcb);

            if (i % 10 == 0) {
                int32_t newValue = value + 100;
                int32_t responseValue = 0;

                std::cout << "Set attribute to value: " << std::dec << newValue << std::endl;

                myProxy->getXAttribute().setValue(newValue, callStatus, responseValue);

                if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                    std::cerr << "Remote call setValue failed!\n";
                    return -1;
                }

                std::cout << "Attribute set to value: " << std::dec << responseValue << std::endl;
            }

            i++;
            std::this_thread::sleep_for(std::chrono::seconds(2));
        }
    }
    return 0;
}
