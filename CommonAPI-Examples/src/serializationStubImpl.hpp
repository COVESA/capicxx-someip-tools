#include <sstream>
#include <v1/commonapi/serialization/SampleStubDefault.hpp>

class SampleStubImpl : public v1::commonapi::serialization::SampleStubDefault {
public:
    SampleStubImpl();
    virtual ~SampleStubImpl();

    virtual void setNameAttribute(v1::commonapi::serialization::Sample::Name value);
};
