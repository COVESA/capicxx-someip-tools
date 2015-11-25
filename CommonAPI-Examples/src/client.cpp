#include <iostream>
#include <iomanip>
#include <dlfcn.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/someip/heartbeatProxy.hpp>
#include <v1/commonapi/someip/mathProxy.hpp>

using namespace v1::commonapi::someip;

void callback(const CommonAPI::CallStatus& callStatus, const int8_t& out) {
    if (callStatus != CommonAPI::CallStatus::SUCCESS) {
        std::cerr << "Remote call failed!\n";
        return;
    }
    std::cout << "Got async message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out;
    std::cout << "' '" << std::dec << (int)out << "'" << std::endl;
}

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::shared_ptr<heartbeatProxyDefault> myProxy
        = runtime->buildProxy<heartbeatProxy>("local", "BMW.ATM");

    std::shared_ptr<mathProxyDefault> myProxy2
        = runtime->buildProxy<mathProxy>("local", "BMW.ATM");

    if (myProxy != NULL && myProxy2 != NULL) {
        myProxy->isAvailableBlocking();
        myProxy2->isAvailableBlocking();

        std::cout << "Proxy created." << std::endl;

        int8_t in_int8 = 42;
        int16_t in_int16 = 42;
        int32_t in_int32 = 42;
        int64_t in_int64 = 42;
        uint8_t in_uint8 = 42;
        uint16_t in_uint16 = 42;
        uint32_t in_uint32 = 42;
        uint64_t in_uint64 = 42;
        bool in_bool = true;
        double in_double = 42;
        float in_float = 42;
        int8_t in_only = 42;
        int8_t out_only = 0;

        int32_t in_num1 = 42;
        int32_t in_num2 = 23;

        while(true) {
            CommonAPI::CallStatus callStatus;
            int8_t out_int8;
            int16_t out_int16;
            int32_t out_int32;
            int64_t out_int64;
            uint8_t out_uint8;
            uint16_t out_uint16;
            uint32_t out_uint32;
            uint64_t out_uint64;
            bool out_bool;
            double out_double;
            float out_float;

            int32_t out_sum;
            int32_t out_diff;

            myProxy->echo_Int8(in_int8, callStatus, out_int8);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Int8' failed!\n";
                return -1;
            }
            myProxy->echo_Int16(in_int16, callStatus, out_int16);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Int16' failed!\n";
                return -1;
            }
            myProxy->echo_Int32(in_int32, callStatus, out_int32);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Int32' failed!\n";
                return -1;
            }
            myProxy->echo_Int64(in_int64, callStatus, out_int64);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Int64' failed!\n";
                return -1;
            }/*
            myProxy->echo_UInt8(in_uint8, callStatus, out_uint8);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_UInt8' failed!\n";
                return -1;
            }
            myProxy->echo_UInt16(in_uint16, callStatus, out_uint16);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_UInt16' failed!\n";
                return -1;
            }
            myProxy->echo_UInt32(in_uint32, callStatus, out_uint32);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_UInt32' failed!\n";
                return -1;
            }
            myProxy->echo_UInt64(in_uint64, callStatus, out_uint64);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_UInt64' failed!\n";
                return -1;
            }
            myProxy->echo_Boolean(in_bool, callStatus, out_bool);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Boolean' failed!\n";
                return -1;
            }
            myProxy->echo_Double(in_double, callStatus, out_double);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Double' failed!\n";
                return -1;
            }
            myProxy->echo_Float(in_float, callStatus, out_float);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'echo_Float' failed!\n";
                return -1;
            }
            myProxy->in_Only(in_only, callStatus);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'in_Only' failed!\n";
                return -1;
            }
            myProxy->out_Only(callStatus, out_only);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'out_Only' failed!\n";
                return -1;
            }
            myProxy->call_Only(callStatus);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'out_Only' failed!\n";
                return -1;
            }

            myProxy2->calc(in_num1, in_num2, callStatus, out_sum, out_diff);
            if (callStatus != CommonAPI::CallStatus::SUCCESS) {
                std::cerr << "Remote call 'calc' failed!\n";
                return -1;
            }*/

            std::cout << "Sent int8 message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_int8;
            std::cout << "' '" << std::dec << (int)in_int8 << "'" << std::endl;
            std::cout << "Got int8 message:     '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_int8;
            std::cout << "' '" << std::dec << (int)out_int8 << "'" << std::endl;

            std::cout << "Sent int16 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_int16;
            std::cout << "' '" << std::dec << (int)in_int16 << "'" << std::endl;
            std::cout << "Got int16 message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_int16;
            std::cout << "' '" << std::dec << (int)out_int16 << "'" << std::endl;

            std::cout << "Sent int32 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_int32;
            std::cout << "' '" << std::dec << (int)in_int32 << "'" << std::endl;
            std::cout << "Got int32 message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_int32;
            std::cout << "' '" << std::dec << (int)out_int32 << "'" << std::endl;

            std::cout << "Sent int64 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_int64;
            std::cout << "' '" << std::dec << (int)in_int64 << "'" << std::endl;
            std::cout << "Got int64 message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_int64;
            std::cout << "' '" << std::dec << (int)out_int64 << "'" << std::endl;
/*
            std::cout << "Sent uint8 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_uint8;
            std::cout << "' '" << std::dec << (int)in_uint8 << "'" << std::endl;
            std::cout << "Got uint8 message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_uint8;
            std::cout << "' '" << std::dec << (int)out_uint8 << "'" << std::endl;

            std::cout << "Sent uint16 message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_uint16;
            std::cout << "' '" << std::dec << (int)in_uint16 << "'" << std::endl;
            std::cout << "Got uint16 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_uint16;
            std::cout << "' '" << std::dec << (int)out_uint16 << "'" << std::endl;

            std::cout << "Sent uint32 message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_uint32;
            std::cout << "' '" << std::dec << (int)in_uint32 << "'" << std::endl;
            std::cout << "Got uint32 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_uint32;
            std::cout << "' '" << std::dec << (int)out_uint32 << "'" << std::endl;

            std::cout << "Sent uint64 message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_uint64;
            std::cout << "' '" << std::dec << (int)in_uint64 << "'" << std::endl;
            std::cout << "Got uint64 message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_uint64;
            std::cout << "' '" << std::dec << (int)out_uint64 << "'" << std::endl;

            std::cout << "Sent boolean message: '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_bool;
            std::cout << "' '" << std::dec << (int)in_bool << "'" << std::endl;
            std::cout << "Got boolean message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_bool;
            std::cout << "' '" << std::dec << (int)out_bool << "'" << std::endl;

            std::cout << "Sent double message:  '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_double;
            std::cout << "' '" << std::dec << (int)in_double << "'" << std::endl;
            std::cout << "Got double message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_double;
            std::cout << "' '" << std::dec << (int)out_double << "'" << std::endl;

            std::cout << "Sent float message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_float;
            std::cout << "' '" << std::dec << (int)in_float << "'" << std::endl;
            std::cout << "Got float message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_float;
            std::cout << "' '" << std::dec << (int)out_float << "'" << std::endl;

            std::cout << "Sent in only message:   '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)in_only;
            std::cout << "' '" << std::dec << (int)in_only << "'" << std::endl;
            std::cout << "Got out only message:    '0x" << std::setw(2) << std::setfill('0') << std::hex << (int)out_only;
            std::cout << "' '" << std::dec << (int)out_only << "'" << std::endl;

            std::cout << "Sent calc message:    num1 = " << in_num1 << " - num2 = " << in_num2 << std::endl;
            std::cout << "Got calc message:     sum  = " << out_sum << " - diff = " << out_diff << std::endl;
*/
            in_int8++;
            in_int16++;
            in_int32++;
            in_int64++;
            in_uint8++;
            in_uint16++;
            in_uint32++;
            in_uint64++;
            in_bool = !in_bool;
            in_double++;
            in_float++;

            in_only++;

            in_num1 += rand() % 10 + 1;
            in_num2 += rand() % 10 + 1;

            std::this_thread::sleep_for(std::chrono::milliseconds(10));
        }
    } else {
        std::cout << "Proxy not created." << std::endl;
    }

    return 0;
}
