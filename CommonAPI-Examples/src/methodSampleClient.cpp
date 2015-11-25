#include <iostream>
#include <iomanip>
#include <dlfcn.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/someip/methodSampleProxy.hpp>

using namespace v1::commonapi::someip;

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::shared_ptr<methodSampleProxyDefault> myProxy
        = runtime->buildProxy<methodSampleProxy>("local", "BMW.ATM");

    if(myProxy != NULL) {
        myProxy->isAvailableBlocking();

        std::cout << "Proxy created." << std::endl;

        while(true) {
            CommonAPI::CallStatus callStatus;
            std::string familyName("Duck");
            std::vector<std::string> firstNames;

            myProxy->setName(familyName, callStatus, firstNames);
            if(callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'setName' failed!\n";
                return -1;
            }

            for(auto firstName : firstNames) {
                std::cout << "first name = " << firstName << std::endl;
            }

            std::this_thread::sleep_for(std::chrono::milliseconds(2000));
        }
    } else {
        std::cout << "Proxy not created." << std::endl;
    }

    return 0;
}
