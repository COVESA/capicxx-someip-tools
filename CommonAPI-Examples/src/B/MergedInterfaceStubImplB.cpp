/* Copyright (C) 2015 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#include "MergedInterfaceStubImplB.hpp"

MergedInterfaceStubImplB::MergedInterfaceStubImplB() {
    cnt = 0;
}

MergedInterfaceStubImplB::~MergedInterfaceStubImplB() {
}

void MergedInterfaceStubImplB::incCounter() {
    cnt++;
    setX3Attribute((int32_t)cnt);
    std::cout <<  "New counter value = " << cnt << "!" << std::endl;
}
