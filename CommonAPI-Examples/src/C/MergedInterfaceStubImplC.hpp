/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef MERGEDINTERFACESTUBIMPLC_H_
#define MERGEDINTERFACESTUBIMPLC_H_

#include <CommonAPI/CommonAPI.hpp>
#include <v2/commonapi/examples/C/MergedInterfaceCStubDefault.hpp>

class MergedInterfaceStubImplC: public v2_1::commonapi::examples::C::MergedInterfaceCStubDefault{

public:
    MergedInterfaceStubImplC();
    virtual ~MergedInterfaceStubImplC();
    virtual void incCounter();

private:
    int cnt;
};

#endif /* MERGEDINTERFACESTUBIMPLC_H_ */
