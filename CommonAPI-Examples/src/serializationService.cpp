#include <dlfcn.h>

#include <chrono>
#include <thread>

#include <CommonAPI/CommonAPI.hpp>

#include "serializationStubImpl.hpp"

int main(int argc, char **argv) {
    std::shared_ptr<CommonAPI::Runtime> runtime = CommonAPI::Runtime::get();
    std::shared_ptr<SampleStubImpl> myService = std::make_shared<SampleStubImpl>();
    if (runtime->registerService("local", "BMW.ATM", myService))
    {
        std::cout << "Service registered." << std::endl;
    }
    else
    {
        std::cout << "Service not registered." << std::endl;
    }

    while (true)
    {
        //myService->incAttribute(); // Change value of attribute, see stub implementation
        std::cout << "Waiting for calls... (Abort with CTRL+C)" << std::endl;
        std::this_thread::sleep_for(std::chrono::seconds(2));
    }

    return 0;
}
