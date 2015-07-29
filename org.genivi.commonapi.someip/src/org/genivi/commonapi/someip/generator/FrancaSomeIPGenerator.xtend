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
import org.eclipse.core.runtime.preferences.DefaultScope
import org.eclipse.core.runtime.preferences.IEclipsePreferences
import org.eclipse.core.runtime.preferences.InstanceScope
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
import org.osgi.framework.FrameworkUtil

import static com.google.common.base.Preconditions.*
import org.genivi.commonapi.core.generator.FDeployManager
import org.franca.deploymodel.dsl.fDeploy.FDModel

class FrancaSomeIPGenerator implements IGenerator
{
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions
    @Inject private extension FInterfaceSomeIPProxyGenerator
    @Inject private extension FInterfaceSomeIPStubAdapterGenerator
    @Inject private extension FInterfaceSomeIPDeploymentGenerator
    @Inject private extension FTypeCollectionSomeIPDeploymentGenerator
    @Inject private FDeployManager fDeployManager

     override doGenerate(Resource input, IFileSystemAccess fileSystemAccess)
    {
        var FModel fModel = null
        var List<FDInterface> deployedInterfaces
        var List<FDInterface> deployedCoreInterfaces
        var List<FDProvider> deployedProviders
        var List<FDTypes> deployedTypeCollections
        var IResource res = null
        var boolean mustGenerate = false
        val String SOMEIP_SPECIFICATION_TYPE = "someip.deployment"
        val String CORE_SPECIFICATION_TYPE = "core.deployment"

		if(input.URI.fileExtension.equals(FDeployManager.fileExtension))
        {
            var model = fDeployManager.loadModel(input.URI, input.URI);
             if(model instanceof FDModel) {

            	deployedInterfaces = getFDInterfaces(model, SOMEIP_SPECIFICATION_TYPE)
            	deployedCoreInterfaces = getFDInterfaces(model, CORE_SPECIFICATION_TYPE)
            	deployedTypeCollections = getFDTypesList(model, SOMEIP_SPECIFICATION_TYPE)
            	deployedProviders = getFDProviders(model, SOMEIP_SPECIFICATION_TYPE)

				val boolean hasInterfaces = (deployedInterfaces.size > 0);
				val boolean hasTypeCollections = (deployedTypeCollections.size() > 0);
				checkArgument(hasInterfaces || hasTypeCollections,
					"\nNo Interfaces/TypeCollections were deployed for " + SOMEIP_SPECIFICATION_TYPE + ", nothing to generate.")

            	for(source : deployedCoreInterfaces) {
            		// We have to merge these deployments into the someip deployment
            		mergeDeployments(source, deployedInterfaces.get(0))
            	}

				if (hasInterfaces)
	            	fModel = deployedInterfaces.get(0).target.model
				else if (hasTypeCollections)
					fModel = deployedTypeCollections.get(0).target.model

				if (fModel != null) {
					createAndInsertAccessors(fModel, deployedInterfaces, deployedTypeCollections)
					mustGenerate = true
				}
			}
		}
        else
        {
            checkArgument(false, "Unknown input: " + input)
        }
        
        try
        {
            var pathfile = input.URI.toPlatformString(false)
            if(pathfile == null)
            {
                pathfile = FPreferencesSomeIP::getInstance.getModelPath(fModel)
            }
            if(pathfile.startsWith("platform:/"))
            {
                pathfile = pathfile.substring(pathfile.indexOf("platform") + 10)
                pathfile = pathfile.substring(pathfile.indexOf(System.getProperty("file.separator")))
            }
        }
        catch(IllegalStateException e)
        {
        } //will be thrown only when the cli calls the francagenerator
        
        if (mustGenerate)
            doGenerateSomeIPComponents(fModel, deployedInterfaces, deployedProviders, deployedTypeCollections, fileSystemAccess, res)
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

    def private doGenerateSomeIPComponents(FModel fModel, List<FDInterface> deployedInterfaces, List<FDProvider> deployedProviders, List<FDTypes> deployedTypeCollections, IFileSystemAccess fileSystemAccess,
        IResource res)
    {
        fModel.typeCollections.forEach [
        	it.generateTypeCollectionDeployment(fileSystemAccess, getAccessor(it), res)
        ]

        fModel.interfaces.forEach [
            var PropertyAccessor interfaceAccessor = getAccessor(it)
            
            val booleanTrue = Boolean.toString(true)
            var IEclipsePreferences node
            var String finalValue = booleanTrue
            if(FrameworkUtil::getBundle(this.getClass()) != null)
            {
                node = DefaultScope::INSTANCE.getNode(PreferenceConstantsSomeIP::SCOPE)
                finalValue = node.get(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, booleanTrue)

                node = InstanceScope::INSTANCE.getNode(PreferenceConstantsSomeIP::SCOPE)
                finalValue = node.get(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, finalValue)
            }
            finalValue = FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATEPROXY_SOMEIP, finalValue)
            if(finalValue.equals(booleanTrue))
            {
                it.generateProxy(fileSystemAccess, interfaceAccessor, deployedProviders, res)
            }
            finalValue = booleanTrue
            if(FrameworkUtil::getBundle(this.getClass()) != null)
            {
                node = DefaultScope::INSTANCE.getNode(PreferenceConstantsSomeIP::SCOPE)
                finalValue = node.get(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, booleanTrue)
                node = InstanceScope::INSTANCE.getNode(PreferenceConstantsSomeIP::SCOPE)
                finalValue = node.get(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, finalValue)
            }
            finalValue = FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATESTUB_SOMEIP, finalValue)
            if(finalValue.equals(booleanTrue))
            {
                 it.generateStubAdapter(fileSystemAccess, interfaceAccessor, deployedProviders, res)
            }
            it.generateDeployment(fileSystemAccess, interfaceAccessor, res)
            it.managedInterfaces.forEach [
                val currentManagedInterface = it
                var PropertyAccessor managedDeploymentAccessor
                if(deployedInterfaces.exists[it.target == currentManagedInterface])
                {
                    managedDeploymentAccessor = new PropertyAccessor(
                        new FDeployedInterface(deployedInterfaces.filter[it.target == currentManagedInterface].last))
                }
                else
                {
                    managedDeploymentAccessor = new PropertyAccessor()
                }
                it.generateProxy(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
                it.generateStubAdapter(fileSystemAccess, managedDeploymentAccessor, deployedProviders, res)
            ]
        ]
    }

}
