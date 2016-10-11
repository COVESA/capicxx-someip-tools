#include <iostream>
#include <iomanip>
#include <dlfcn.h>
#include <unistd.h>

#include <CommonAPI/CommonAPI.hpp>

#include <v1/commonapi/serialization/SampleProxy.hpp>

using namespace v1::commonapi::serialization;

int main(int argc, char **argv) {
    std::shared_ptr< CommonAPI::Runtime > runtime = CommonAPI::Runtime::get();

    std::shared_ptr<SampleProxyDefault> itsProxy
        = runtime->buildProxy<SampleProxy>("local", "BMW.ATM");

    while (!itsProxy->isAvailable())
    {
        std::this_thread::sleep_for(std::chrono::microseconds(10));
    }
    std::cout << "Service \"E05Sample\" is available." << std::endl;

    CommonAPI::CallStatus itsStatus;

    Sample::Name aName("Donald", "Duck");
    Sample::Name bName;

    itsProxy->getNameAttribute().setValue(aName, itsStatus, bName);
    std::cout << "Attribute(response from setValue): " << bName.getGiven() << " " << bName.getFamily() << std::endl;

    itsProxy->getNameAttribute().getValue(itsStatus, bName);
    std::cout << "Attribute(response from getValue): " << bName.getGiven() << " " << bName.getFamily() << std::endl;

    return 0;
}
