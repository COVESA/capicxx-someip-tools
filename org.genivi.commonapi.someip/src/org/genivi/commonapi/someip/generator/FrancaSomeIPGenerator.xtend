/* Copyright (C) 2014, 2015 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.List
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.franca.FModel
import org.franca.deploymodel.core.FDeployedInterface
import org.franca.deploymodel.core.FDeployedTypeCollection
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.franca.deploymodel.dsl.fDeploy.FDTypes
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.genivi.commonapi.core.generator.FDeployManager
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.eclipse.emf.common.util.URI

class FrancaSomeIPGenerator implements IGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions
    @Inject private extension FInterfaceSomeIPProxyGenerator
    @Inject private extension FInterfaceSomeIPStubAdapterGenerator
    @Inject private extension FInterfaceSomeIPDeploymentGenerator
    @Inject private FDeployManager fDeployManager

    val String SOMEIP_SPECIFICATION_TYPE = "someip.deployment"
    val String CORE_SPECIFICATION_TYPE = "core.deployment"
    var List<FDProvider> deployedProviders
        
    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {

        deployedProviders = null
        if (input.URI.fileExtension.equals(FDeployManager.fileExtension)) {
            generate(input.URI, fileSystemAccess)
        } 
    }
    
    def private generate(URI input, IFileSystemAccess fileSystemAccess) {

        // parent model
        var model = fDeployManager.loadModel(input, input);
        if (model instanceof FDModel) {
    
            //System.out.println("generating : " + input.lastSegment) 

            var deployedInterfaces = getFDInterfaces(model, SOMEIP_SPECIFICATION_TYPE)
            var deployedCoreInterfaces = getFDInterfaces(model, CORE_SPECIFICATION_TYPE)
            var deployedTypeCollections = getFDTypesList(model, SOMEIP_SPECIFICATION_TYPE)
            if(deployedProviders == null) {
                deployedProviders = getFDProviders(model, SOMEIP_SPECIFICATION_TYPE)
            }
            var boolean hasInterfaces = (deployedInterfaces.size > 0);
            var boolean hasTypeCollections = (deployedTypeCollections.size() > 0);

            var FModel fModel = null
            if (hasInterfaces)
                fModel = deployedInterfaces.get(0).target.model
            else if (hasTypeCollections)
                fModel = deployedTypeCollections.get(0).target.model

            if (fModel != null) {

                // We have to merge core deployments into the someip deployment
                for (source : deployedCoreInterfaces) {
                    mergeDeployments(source, deployedInterfaces.get(0))
                }

                // actually generate code
                createAndInsertAccessors(fModel, deployedInterfaces, deployedTypeCollections)
                doGenerateSomeIPComponents(fModel, deployedInterfaces, deployedProviders,
                    deployedTypeCollections, fileSystemAccess, null)
            }

            // included models 
            for (import_ : model.imports) {
                val importUri = import_.getImportURI
                if (!importUri.contains("deployment_spec") && importUri.endsWith(".fdepl")) {
                    val fdeplUri = URI.createURI(importUri)

                    //System.out.println("loading and generating model from import: " + fdeplUri.lastSegment)
                    val nextUri = fdeplUri.resolve(input);

                    // recursively call me again
                    generate(nextUri, fileSystemAccess)
                }
            }
        }
    }
    
    
    
    def private createAndInsertAccessors(FModel _model, List<FDInterface> _interfaces, List<FDTypes> _typeCollections) {
        val defaultDeploymentAccessor = new PropertyAccessor()
        _model.typeCollections.forEach [
            var PropertyAccessor typeCollectionDeploymentAccessor
            val currentTypeCollection = it
            if (_typeCollections.exists[it.target == currentTypeCollection]) {
                typeCollectionDeploymentAccessor = new PropertyAccessor(
                    new FDeployedTypeCollection(_typeCollections.filter[it.target == currentTypeCollection].last))
            } else {
                typeCollectionDeploymentAccessor = defaultDeploymentAccessor
            }
            insertAccessor(currentTypeCollection, typeCollectionDeploymentAccessor)
        ]

        _model.interfaces.forEach [
            var PropertyAccessor interfaceDeploymentAccessor
            val currentInterface = it
            if (_interfaces.exists[it.target == currentInterface]) {
                interfaceDeploymentAccessor = new PropertyAccessor(
                    new FDeployedInterface(_interfaces.filter[it.target == currentInterface].last))
            } else {
                interfaceDeploymentAccessor = defaultDeploymentAccessor
            }
            insertAccessor(currentInterface, interfaceDeploymentAccessor)
        ]
    }

    def private doGenerateSomeIPComponents(FModel fModel, List<FDInterface> deployedInterfaces,
        List<FDProvider> deployedProviders, List<FDTypes> deployedTypeCollections, IFileSystemAccess fileSystemAccess,
        IResource res) {

        var typeCollectionsToGenerate = fModel.typeCollections.toSet
        var interfacesToGenerate = fModel.interfaces.toSet

        typeCollectionsToGenerate.forEach [
            it.generateTypeCollectionDeployment(fileSystemAccess, getAccessor(it), res)
        ]

        interfacesToGenerate.forEach [
            var PropertyAccessor interfaceAccessor = getAccessor(it)
            if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, "true").
                equals("true")) {
                it.generateProxy(fileSystemAccess, interfaceAccessor, deployedProviders, res)
            }
            if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, "true").
                equals("true")) {
                it.generateStubAdapter(fileSystemAccess, interfaceAccessor, deployedProviders, res)
            }
            it.generateDeployment(fileSystemAccess, interfaceAccessor, res)
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if (deployedInterfaces.exists[it.target == currentManagedInterface]) {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(deployedInterfaces.filter[it.target == currentManagedInterface].last))
                } else {
                    managedDeploymentAccessor = new PropertyAccessor()
                }
                it.generateProxy(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
                it.generateStubAdapter(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
            ]
        ]
    }

}
