/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef MERGEDINTERFACESTUBIMPLA_H_
#define MERGEDINTERFACESTUBIMPLA_H_

#include <CommonAPI/CommonAPI.hpp>
#include <v1/commonapi/examples/A/MergedInterfaceAStubDefault.hpp>

class MergedInterfaceStubImplA: public v1_0::commonapi::examples::A::MergedInterfaceAStubDefault{

public:
    MergedInterfaceStubImplA();
    virtual ~MergedInterfaceStubImplA();
    virtual void incCounter();

private:
    int cnt;
};

#endif /* MERGEDINTERFACESTUBIMPLA_H_ */
