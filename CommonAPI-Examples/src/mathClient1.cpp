#include <iostream>
#include <iomanip>
#include <dlfcn.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/someip/heartbeatProxy.hpp>
#include <v1/commonapi/someip/mathProxy.hpp>

using namespace v1::commonapi::someip;

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::shared_ptr<mathProxyDefault> myProxy
        = runtime->buildProxy<mathProxy>("local", "BMW.ATM");

    if(myProxy != NULL) {
        myProxy->isAvailableBlocking();

        std::cout << "Proxy created." << std::endl;

        int32_t in_num1 = 50;
        int32_t in_num2 = 10;

        // Subscribe to broadcast
        myProxy->getResultsEvent().subscribe([&](const int32_t& sum, const int32_t& diff) {
            std::cout << "Received status event: sum=" << sum << " - diff=" << diff << std::endl;
        });

        while(true) {
            CommonAPI::CallStatus callStatus;
            int32_t out_sum;
            int32_t out_diff;

            myProxy->calc(in_num1, in_num2, callStatus, out_sum, out_diff);
            if(callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'calc' failed!\n";
                return -1;
            }

            std::cout << "Sent calc message:    num1 = " << in_num1 << " - num2 = " << in_num2 << std::endl;
            std::cout << "Got calc message:     sum  = " << out_sum << " - diff = " << out_diff << std::endl;

            in_num2 += 1;


            std::this_thread::sleep_for(std::chrono::milliseconds(2000));
        }
    } else {
        std::cout << "Proxy not created." << std::endl;
    }

    return 0;
}
