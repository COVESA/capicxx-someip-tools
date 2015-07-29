#include <sstream>
#include <v1_42/commonapi/serialization/SampleStubDefault.hpp>

class SampleStubImpl : public v1_42::commonapi::serialization::SampleStubDefault {
public:
    SampleStubImpl();
    virtual ~SampleStubImpl();

    virtual void setNameAttribute(v1_42::commonapi::serialization::Sample::Name value);
};
