/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.validator;

public class Triple<FrancaPackage, TypeCollectionList, InterfaceList> {

    public final FrancaPackage packageName;
    public final TypeCollectionList typeCollectionList;
    public final InterfaceList interfaceList;

    public Triple(FrancaPackage packageName, TypeCollectionList typeCollectionList,
            InterfaceList interfaceList) {
        this.packageName = packageName;
        this.interfaceList = interfaceList;
        this.typeCollectionList = typeCollectionList;
    }

}