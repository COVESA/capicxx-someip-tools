#include <dlfcn.h>

#include <chrono>
#include <iostream>
#include <thread>

#include <CommonAPI/CommonAPI.hpp>

#include "heartbeatStubImpl.hpp"
#include "mathStubImpl.hpp"

int main(int argc, char **argv) {
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    std::shared_ptr<heartbeatStubImpl> heartbeatService = std::make_shared<heartbeatStubImpl>();
    if (runtime->registerService("local", "BMW.ATM", heartbeatService))
    {
        std::cout << "Heartbeat service registered." << std::endl;
    }
    else
    {
        std::cout << "Heartbeat service not registered." << std::endl;
        return -1;
    }

    std::shared_ptr<mathStubImpl> mathService = std::make_shared<mathStubImpl>();
    if (runtime->registerService("local", "BMW.ATM", mathService))
    {
        std::cout << "Math service registered." << std::endl;
    }
    else
    {
        std::cout << "Math service not registered." << std::endl;
        return -1;
    }

    while (true)
    {
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(60));
    }

    return 0;
}
