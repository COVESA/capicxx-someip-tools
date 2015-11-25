#include <iostream>
#include <iomanip>
#include <dlfcn.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/someip/MapProxy.hpp>

using namespace v1::commonapi::someip;

void recv_cb(const CommonAPI::CallStatus& callStatus, const int32_t& val) {
    std::cout << "Got attribute value callback: " << std::dec << val << std::endl;
}

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::shared_ptr<MapProxyDefault> myProxy
        = runtime->buildProxy<MapProxy>("local", "BMW.ATM");

    if (myProxy != nullptr) {
        myProxy->isAvailableBlocking();

        // Subscribe for receiving values
        myProxy->getMyMapAttribute().getChangedEvent().subscribe([&](const std::unordered_map<uint16_t, int8_t>& val) {
            //std::cout << "Received change message: " << std::dec << val << std::endl;
        });

        CommonAPI::CallStatus callStatus;
        int32_t i = 1;

        std::function<void(const CommonAPI::CallStatus&, int32_t)> fcb = recv_cb;
    //    myProxy->getMyMapAttribute().setValueAsync(1000 * i, fcb);

        //std::this_thread::sleep_for(std::chrono::seconds(2));

        while (i < 5) {
                std::unordered_map<uint16_t, int8_t> newValue({{42, 24}, {68, 86}});
                std::unordered_map<uint16_t, int8_t> responseValue;

                for(auto x : newValue) {
                    std::cout << "Attribute key is: " << std::dec << x.first << std::endl;
                    std::cout << "Attribute value is: " << std::dec << (int)x.second << std::endl;
                }

                myProxy->getMyMapAttribute().setValue(newValue, callStatus, responseValue);

                for(auto x : responseValue) {
                    std::cout << "Set attribute key to: " << std::dec << x.first << std::endl;
                    std::cout << "Set attribute value to: " << std::dec << (int)x.second << std::endl;
                }

                ///////////////////////////////////////////////////////////////

                std::vector<uint16_t> newArrayValue({42, 24, 68, 86});
                std::vector<uint16_t> responseArrayValue;

                for(size_t i = 0; i < newArrayValue.size(); i++) {
                    std::cout << "Array value " << i << " is: " << std::dec << newArrayValue[i] << std::endl;
                }

                myProxy->getMyArrayAttribute().setValue(newArrayValue, callStatus, responseArrayValue);

                for(size_t i = 0; i < responseArrayValue.size(); i++) {
                    std::cout << "Set array value " << i << " to: " << std::dec << responseArrayValue[i] << std::endl;
                }

            i++;
            std::this_thread::sleep_for(std::chrono::seconds(2));
        }
    }
    return 0;
}
