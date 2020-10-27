/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import com.google.inject.Inject
import org.eclipse.core.resources.IResource
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArgument
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.franca.core.franca.FAttribute
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.core.franca.FBroadcast

class FInterfaceSomeIPDeploymentGenerator extends FTypeCollectionSomeIPDeploymentGenerator {
	@Inject extension FrancaGeneratorExtensions
	@Inject extension FrancaSomeIPGeneratorExtensions
	@Inject extension FrancaSomeIPDeploymentAccessorHelper

    def generateDeployment(FInterface fInterface, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, IResource modelid) {

        if(FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATE_CODE_SOMEIP, "true").equals("true")) {
            fileSystemAccess.generateFile(fInterface.someipDeploymentHeaderPath,  IFileSystemAccess.DEFAULT_OUTPUT,
                fInterface.generateDeploymentHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(fInterface.someipDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT,
                fInterface.generateDeploymentSource(deploymentAccessor, modelid))
        }
        else {
            // feature: suppress code generation
            fileSystemAccess.generateFile(fInterface.someipDeploymentHeaderPath,  IFileSystemAccess.DEFAULT_OUTPUT, PreferenceConstantsSomeIP::NO_CODE)
            fileSystemAccess.generateFile(fInterface.someipDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT, PreferenceConstantsSomeIP::NO_CODE)
        }
    }

    def private generateDeploymentHeader(FInterface _interface,
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»

        #ifndef «_interface.defineName»_SOMEIP_DEPLOYMENT_HPP_
        #define «_interface.defineName»_SOMEIP_DEPLOYMENT_HPP_

        «val DeploymentHeaders = _interface.getDeploymentInputIncludes(_accessor)»
        «FOR deploymentHeader : DeploymentHeaders.sort»
            «IF !deploymentHeader.equals(someipDeploymentHeaderPath(_interface))»
                #include <«deploymentHeader»>
            «ENDIF»
        «ENDFOR»

        «startInternalCompilation»
        #include <CommonAPI/SomeIP/Deployment.hpp>
        «endInternalCompilation»

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»
        «_interface.generateDeploymentNamespaceBegin»

        // Interface-specific deployment types
        «FOR t: _interface.types.filter[it instanceof FEnumerationType]»
            «val deploymentType = t.generateDeploymentType(0, _accessor)»
            typedef «deploymentType» «t.name»Deployment_t;
        «ENDFOR»
        «FOR t: _interface.types.filter[!(it instanceof FEnumerationType)]»
            «val deploymentType = t.generateDeploymentType(0, _accessor)»
            typedef «deploymentType» «t.name»Deployment_t;
        «ENDFOR»

        // Type-specific deployments
        «FOR t: _interface.types»
            «t.generateDeploymentDeclaration(_interface, _accessor)»
        «ENDFOR»

        // Attribute-specific deployments
        «FOR a: _interface.attributes»
            «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
            «a.generateDeploymentDeclaration(_interface, overwriteAccessor)»
        «ENDFOR»

        // Argument-specific deployment
        «FOR m : _interface.methods»
            «FOR a : m.inArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDeclaration(m, _interface, overwriteAccessor)»
            «ENDFOR»
            «FOR a : m.outArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDeclaration(m, _interface, overwriteAccessor)»
            «ENDFOR»
        «ENDFOR»

        // Broadcast-specific deployments
        «FOR broadcast : _interface.broadcasts»
            «FOR a : broadcast.outArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDeclaration(broadcast, _interface, overwriteAccessor)»
            «ENDFOR»
        «ENDFOR»

        «_interface.generateDeploymentNamespaceEnd»
        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»

        #endif // «_interface.defineName»_SOMEIP_DEPLOYMENT_HPP_
    '''

    def private generateDeploymentSource(FInterface _interface,
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»
        #include <«_interface.someipDeploymentHeaderPath»>

        «_interface.generateVersionNamespaceBegin»
        «_interface.model.generateNamespaceBeginDeclaration»
        «_interface.generateDeploymentNamespaceBegin»

        // Type-specific deployments
        «FOR t: _interface.types»
            «t.generateDeploymentDefinition(_interface,_accessor)»
        «ENDFOR»

        // Attribute-specific deployments
        «FOR a: _interface.attributes»
            «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
            «a.generateDeploymentDefinition(_interface,overwriteAccessor)»
        «ENDFOR»

        // Argument-specific deployment
        «FOR m : _interface.methods»
            «FOR a : m.inArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDefinition(m, _interface, overwriteAccessor)»
            «ENDFOR»
            «FOR a : m.outArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDefinition(m, _interface, overwriteAccessor)»
            «ENDFOR»
        «ENDFOR»

        // Broadcast-specific deployments
        «FOR broadcast : _interface.broadcasts»
            «FOR a : broadcast.outArgs»
                «val overwriteAccessor = _accessor.getOverwriteAccessor(a)»
                «a.generateDeploymentDefinition(broadcast, _interface, overwriteAccessor)»
            «ENDFOR»
        «ENDFOR»

        «_interface.generateDeploymentNamespaceEnd»
        «_interface.model.generateNamespaceEndDeclaration»
        «_interface.generateVersionNamespaceEnd»
    '''

    /////////////////////////////////////
    // Generate deployment declarations //
    /////////////////////////////////////
    def protected dispatch String generateDeploymentDeclaration(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute) || (_attribute.array && _accessor.hasDeployment(_attribute))) {
            return "COMMONAPI_EXPORT extern " + _attribute.getDeploymentType(_interface, true) + " " + _attribute.name + "Deployment;"
        }
        return ""
    }

    def protected String generateDeploymentDeclaration(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument) || (_argument.array && _accessor.hasDeployment(_argument))) {
            return "COMMONAPI_EXPORT extern " + _argument.getDeploymentType(_interface, true) + " " + _method.name + "_" + _argument.name + "Deployment;"
        }
    }

    def protected String generateDeploymentDeclaration(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument) || (_argument.array && _accessor.hasDeployment(_argument))) {
            return "COMMONAPI_EXPORT extern " + _argument.getDeploymentType(_interface, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment;"
        }
    }

    /////////////////////////////////////
    // Generate deployment definitions //
    /////////////////////////////////////
    def protected dispatch String generateDeploymentDefinition(FAttribute _attribute, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_attribute) || (_attribute.array && _accessor.hasDeployment(_attribute))) {
            var String definition = ""
            if (_attribute.array && _accessor.hasNonArrayDeployment(_attribute)) {
                if (_attribute.type.derived !== null) {
                    definition += _attribute.type.derived.generateDeploymentParameterDefinitions(_interface, _accessor)
                }
                definition += _attribute.type.getDeploymentType(_interface, true) + " " + _attribute.name + "ElementDeployment("
                definition += getDeploymentParameter(_attribute.type, _attribute, _interface, _accessor)
                definition += ");\n";
            }
            else {
		        if (!_attribute.array && _attribute.type.derived !== null) {
		            definition += _attribute.type.derived.generateDeploymentParameterDefinitions(_interface, _accessor)
		        }
            }
            definition += _attribute.getDeploymentType(_interface, true) + " " + _attribute.name + "Deployment("
            if (_attribute.array && _accessor.hasNonArrayDeployment(_attribute)) {
                definition += "&" + _attribute.name + "ElementDeployment, "
                definition += getArrayDeploymentParameter(_attribute.type, _attribute, _interface, _accessor)
            } else {
                definition += _attribute.getDeploymentParameter(_attribute, _interface, _accessor)
            }
            definition += ");"
            return definition
        }
        return ""
    }

    def protected String generateDeploymentDefinition(FArgument _argument, FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument) || (_argument.array && _accessor.hasDeployment(_argument))) {
            var String definition = ""
            if (_argument.array && _accessor.hasNonArrayDeployment(_argument)) {
                if (_argument.type.derived !== null) {
                    definition += _argument.type.derived.generateDeploymentParameterDefinitions(_interface, _accessor)
                }
                definition += _argument.type.getDeploymentType(_interface, true) + " " + _method.name + "_" + _argument.name + "ElementDeployment("
                definition += getDeploymentParameter(_argument.type, _argument, _interface, _accessor)
                definition += ");\n";
            }
            else {
                 if (!_argument.array && _argument.type.derived !== null) {
                    definition += _argument.type.derived.generateDeploymentParameterDefinitions(_interface, _accessor)
                 }
            }
            definition += _argument.getDeploymentType(_interface, true) + " " + _method.name + "_" + _argument.name + "Deployment("
            if (_argument.array && _accessor.hasNonArrayDeployment(_argument)) {
                definition += "&" + _method.name + "_" + _argument.name + "ElementDeployment, "
                definition += getArrayDeploymentParameter(_argument.type, _argument, _interface, _accessor)
            } else {
                definition += _argument.getDeploymentParameter(_argument, _interface, _accessor)
            }
            definition += ");"
            return definition
        }
    }

    def protected String generateDeploymentDefinition(FArgument _argument, FBroadcast _broadcast, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_argument) || (_argument.array && _accessor.hasDeployment(_argument))) {
            var String definition = ""
            if (_argument.array && _accessor.hasNonArrayDeployment(_argument)) {
                definition += _argument.type.getDeploymentType(_interface, true) + " " + _broadcast.name + "_" + _argument.name + "ElementDeployment("
                definition += getDeploymentParameter(_argument.type, _argument, _interface, _accessor)
                definition += ");\n";
            }
            else {
		        if (!_argument.array && _argument.type.derived !== null) {
		            definition += _argument.type.derived.generateDeploymentParameterDefinitions(_interface, _accessor)
		        }
            }
            definition += _argument.getDeploymentType(_interface, true) + " " + _broadcast.name + "_" + _argument.name + "Deployment("
            if (_argument.array && _accessor.hasNonArrayDeployment(_argument)) {
                definition += "&" + _broadcast.name + "_" + _argument.name + "ElementDeployment, "
                definition += getArrayDeploymentParameter(_argument.type, _argument, _interface, _accessor)
            } else {
                definition += _argument.getDeploymentParameter(_argument, _interface, _accessor)
            }
            definition += ");"
            return definition
        }
    }
}
