/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.io.File
import java.util.HashSet
import java.util.LinkedList
import java.util.List
import java.util.Map
import java.util.Set
import javax.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.eclipse.xtext.generator.IGenerator
import org.franca.core.franca.FModel
import org.franca.deploymodel.core.FDeployedInterface
import org.franca.deploymodel.core.FDeployedTypeCollection
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDTypes
import org.genivi.commonapi.core.generator.FDeployManager
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.deploymodel.dsl.fDeploy.FDExtensionRoot

class FrancaSomeIPGenerator implements IGenerator {
	@Inject extension FrancaGeneratorExtensions
	@Inject extension FrancaSomeIPGeneratorExtensions
	@Inject extension FInterfaceSomeIPProxyGenerator
	@Inject extension FInterfaceSomeIPStubAdapterGenerator
	@Inject extension FInterfaceSomeIPDeploymentGenerator

    @Inject FDeployManager fDeployManager

    val String SOMEIP_SPECIFICATION_TYPE = "someip.deployment"
    val String CORE_SPECIFICATION_TYPE = "core.deployment"

    override doGenerate(Resource input, IFileSystemAccess fileSystemAccess) {
        if (!input.URI.fileExtension.equals(FDeployManager.fileExtension)) {
                return
        }

        var List<FDInterface> deployedInterfaces = new LinkedList<FDInterface>()
        var List<FDTypes> deployedTypeCollections = new LinkedList<FDTypes>()
        var List<FDExtensionRoot> deployedProviders = new LinkedList<FDExtensionRoot>()
        var IResource res = null

        var rootModel = fDeployManager.loadModel(input.URI, input.URI);

        generatedFiles_ = new HashSet<String>()

        withDependencies_ = FPreferencesSomeIP::instance.getPreference(
            PreferenceConstantsSomeIP::P_GENERATE_DEPENDENCIES_SOMEIP, "true"
        ).equals("true")

        // models holds the map of all models from imported .fidl files
        var models = fDeployManager.fidlModels
        // deployments holds the map of all models from imported .fdepl files
        var deployments = fDeployManager.deploymentModels

        if (rootModel instanceof FDModel) {
            deployments.put(input.URI.toString , rootModel)
        } else {
            System.err.println("CommonAPI-SomeIP requires a deployment model!")
            return
        }

        for (itsEntry : deployments.entrySet) {
            val itsDeployment = itsEntry.value

            // Get Core deployments
            val itsCoreInterfaces = getFDInterfaces(itsDeployment, CORE_SPECIFICATION_TYPE)
            val itsCoreTypeCollections = getFDTypesList(itsDeployment, CORE_SPECIFICATION_TYPE)

            // Get SOME/IP deployments
            val itsSomeIPInterfaces = getFDInterfaces(itsDeployment, SOMEIP_SPECIFICATION_TYPE)
            val itsSomeIPTypeCollections = getFDTypesList(itsDeployment, SOMEIP_SPECIFICATION_TYPE)
            val itsSomeIPProviders = getFDProviders(itsDeployment, SOMEIP_SPECIFICATION_TYPE)

            // Merge Core deployments for interfaces to their SOME/IP deployments
            for (itsSomeIPDeployment : itsSomeIPInterfaces)
                for (itsCoreDeployment : itsCoreInterfaces)
                    mergeDeployments(itsCoreDeployment, itsSomeIPDeployment)

            // Merge Core deployments for type collections to their SOME/IP deployments
            for (itsSomeIPDeployment : itsSomeIPTypeCollections)
                for (itsCoreDeployment : itsCoreTypeCollections)
                    mergeDeployments(itsCoreDeployment, itsSomeIPDeployment)

            deployedInterfaces.addAll(itsSomeIPInterfaces)
            deployedTypeCollections.addAll(itsSomeIPTypeCollections)
            deployedProviders.addAll(itsSomeIPProviders)
        }

        doGenerateDeployment(rootModel as FDModel, deployments, models,
            deployedInterfaces, deployedTypeCollections, deployedProviders,
            fileSystemAccess, res, true)

        fDeployManager.clearFidlModels
        fDeployManager.clearDeploymentModels
    }

    def private void doGenerateDeployment(FDModel _deployment,
                                          Map<String, FDModel> _deployments,
                                          Map<String, FModel> _models,
                                          List<FDInterface> _interfaces,
                                          List<FDTypes> _typeCollections,
                                          List<FDExtensionRoot> _providers,
                                          IFileSystemAccess _access,
                                          IResource _res,
                                          boolean _mustGenerate) {
        val String deploymentName
            = _deployments.entrySet.filter[it.value == _deployment].head.key

        var int lastIndex = deploymentName.lastIndexOf(File.separatorChar)
        if (lastIndex == -1) {
            lastIndex = deploymentName.lastIndexOf('/')
        }

        var String basePath = deploymentName.substring(
            0, lastIndex)

        var Set<String> itsImports = new HashSet<String>()
        for (anImport : _deployment.imports) {
            val String cannonical = basePath.getCanonical(anImport.importURI)
            itsImports.add(cannonical)
        }

        for (itsEntry : _models.entrySet) {
            if (itsImports.contains(itsEntry.key)) {
                doInsertAccessors(itsEntry.value, _interfaces, _typeCollections)
            }
        }

        for (itsEntry : _deployments.entrySet) {
            if (itsImports.contains(itsEntry.key)) {
                doGenerateDeployment(itsEntry.value, _deployments, _models,
                    _interfaces, _typeCollections, _providers,
                    _access, _res, withDependencies_)
            }
        }

        if (_mustGenerate) {
            for (itsEntry : _models.entrySet) {
                if (itsImports.contains(itsEntry.key)) {

                    doGenerateModel(itsEntry.value, _models,
                        _interfaces, _typeCollections, _providers,
                        _access, _res)
                }
            }
        }
    }

    def private void doGenerateModel(FModel _model,
                                     Map<String, FModel> _models,
                                     List<FDInterface> _interfaces,
                                     List<FDTypes> _typeCollections,
                                     List<FDExtensionRoot> _providers,
                                     IFileSystemAccess _access,
                                     IResource _res) {
        val String modelName
            = _models.entrySet.filter[it.value == _model].head.key

        if (generatedFiles_.contains(modelName)) {
            return
        }

        generatedFiles_.add(modelName)

        doGenerateComponents(_model,
            _interfaces, _typeCollections, _providers,
            _access, _res)

        if (withDependencies_) {
            for (itsEntry : _models.entrySet) {
                var FModel itsModel = itsEntry.value
                if (itsModel !== null && itsModel != _model) {
                    doGenerateComponents(itsModel,
                        _interfaces, _typeCollections, _providers,
                        _access, _res)
                }
            }
        }
    }

    def private doInsertAccessors(FModel _model,
                                  List<FDInterface> _interfaces,
                                  List<FDTypes> _typeCollections) {
        val defaultDeploymentAccessor = new PropertyAccessor()

        _typeCollections.forEach [
            val currentTypeCollection = it
            val PropertyAccessor typeCollectionDeploymentAccessor = new PropertyAccessor(
                new FDeployedTypeCollection(it))
            insertAccessor(currentTypeCollection.target, typeCollectionDeploymentAccessor)
        ]

        _model.typeCollections.forEach [
            val currentTypeCollection = it
            if (!_typeCollections.exists[it.target == currentTypeCollection]) {
                insertAccessor(currentTypeCollection, defaultDeploymentAccessor)
            }

        ]

        _interfaces.forEach [
            val currentInterface = it
            val PropertyAccessor interfaceDeploymentAccessor = new PropertyAccessor(
                new FDeployedInterface(it))
            insertAccessor(currentInterface.target, interfaceDeploymentAccessor)
        ]

        _model.interfaces.forEach [
            val currentInterface = it
            if (!_interfaces.exists[it.target == currentInterface]) {
                insertAccessor(currentInterface, defaultDeploymentAccessor)
            }
        ]
    }

    def private doGenerateComponents(FModel _model,
                                     List<FDInterface> _interfaces,
                                     List<FDTypes> _typeCollections,
                                     List<FDExtensionRoot> _providers,
                                     IFileSystemAccess fileSystemAccess,
                                     IResource res) {
        var typeCollectionsToGenerate = _model.typeCollections.toSet
        var interfacesToGenerate = _model.interfaces.toSet

        typeCollectionsToGenerate.forEach [
            it.generateTypeCollectionDeployment(fileSystemAccess, getSomeIpAccessor(it), res)
        ]

        interfacesToGenerate.forEach [
            var PropertyAccessor interfaceAccessor = getSomeIpAccessor(it)
            if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, "true").
                equals("true")) {
                it.generateProxy(fileSystemAccess, interfaceAccessor, _providers, res)
            }
            if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, "true").
                equals("true")) {
                it.generateStubAdapter(fileSystemAccess, interfaceAccessor, _providers, res)
            }
            if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATE_COMMON_SOMEIP, "true").
                equals("true")) {
                it.generateDeployment(fileSystemAccess, interfaceAccessor, res)
            }
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if (_interfaces.exists[it.target == currentManagedInterface]) {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(_interfaces.filter[it.target == currentManagedInterface].last))
                } else {
                    managedDeploymentAccessor = new PropertyAccessor()
                }
                if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, "true").
                    equals("true")) {
                    it.generateProxy(fileSystemAccess, managedDeploymentAccessor, _providers, res)
                }
                if (FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, "true").
                    equals("true")) {
                    it.generateStubAdapter(fileSystemAccess, managedDeploymentAccessor, _providers, res)
                }
            ]
        ]
    }

    var boolean withDependencies_;
	var Set<String> generatedFiles_;
}
