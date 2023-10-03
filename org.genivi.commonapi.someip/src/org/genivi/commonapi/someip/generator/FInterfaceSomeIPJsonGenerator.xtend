/* Copyright (C) 2014, 2018 BMW Group
 * Author: Florian Meier (Florian.Meier@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.List
import java.util.LinkedList
import javax.inject.Inject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FInterface
import org.franca.deploymodel.ext.providers.FDeployedProvider
import org.franca.deploymodel.ext.providers.ProviderUtils
import org.franca.deploymodel.dsl.fDeploy.FDExtensionRoot
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP

class FInterfaceSomeIPJsonGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions

    def generateJSONStubAdapter(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, List<FDExtensionRoot> providers) {
        if (FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATE_CODE_SOMEIP, "true").
            equals("true")) {
            fileSystemAccess.generateFile(fInterface.someipStubAdapterSourcePath,
                PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
                fInterface.generateStubJSON(deploymentAccessor, providers))
        }
    }

    def private generateStubJSON(FInterface _interface, PropertyAccessor _accessor, List<FDExtensionRoot> providers) {
        var List<FDExtensionRoot> filtered = new LinkedList<FDExtensionRoot>()

        for (i : providers) {
            if (ProviderUtils.getInstances(i).filter[target == _interface].size() != 0) {
                filtered.add(i);
            }

        }
        if (_interface.getSomeIpServiceID == "UNDEFINED_SERVICE_ID") {
'''
{
    «FOR p : filtered SEPARATOR ','»
        "«_interface.fullyQualifiedName»" : {
        }
    «ENDFOR»
}
'''
        } else {
'''
{
    «FOR p : filtered SEPARATOR ','»
        «val PropertyAccessor providerAccessor = new PropertyAccessor(new FDeployedProvider(p))»
        "«_interface.fullyQualifiedName»" : {
            "service_id": «Integer.decode(_interface.getSomeIpServiceID)»,
            "instances" : {
                «FOR i : ProviderUtils.getInstances(p).filter[target == _interface] SEPARATOR ','»
                    "«providerAccessor.getInstanceId(i)»": «providerAccessor.getSomeIpInstanceID(i)»
                «ENDFOR»
            }
        }
    «ENDFOR»
}
'''
        }
    }

    def private someipStubAdapterSourceFile(FInterface fInterface) {
        fInterface.elementName + "SomeIPCatalog.json"
    }

    def private someipStubAdapterSourcePath(FInterface fInterface) {
        fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipStubAdapterSourceFile
    }
}
