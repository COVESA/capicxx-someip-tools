/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import com.google.inject.Inject
import java.util.List
import org.eclipse.core.resources.IResource
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.generator.IFileSystemAccess
import org.franca.core.franca.FArgument
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FField
import org.franca.core.franca.FMapType
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.franca.core.franca.FTypedElement
import org.franca.core.franca.FIntegerInterval

class FTypeCollectionSomeIPDeploymentGenerator {
    @Inject extension FrancaGeneratorExtensions
    @Inject extension FrancaSomeIPGeneratorExtensions
    @Inject extension FrancaSomeIPDeploymentAccessorHelper

    def generateTypeCollectionDeployment(FTypeCollection tc, IFileSystemAccess fileSystemAccess,
        PropertyAccessor deploymentAccessor, IResource modelid) {

        if(FPreferencesSomeIP::getInstance.getPreference(PreferenceConstantsSomeIP::P_GENERATE_CODE_SOMEIP, "true").equals("true")) {
            fileSystemAccess.generateFile(tc.someipDeploymentHeaderPath, IFileSystemAccess.DEFAULT_OUTPUT,
                tc.generateDeploymentHeader(deploymentAccessor, modelid))
            fileSystemAccess.generateFile(tc.someipDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT,
                tc.generateDeploymentSource(deploymentAccessor, modelid))
        }
        else {
            fileSystemAccess.generateFile(tc.someipDeploymentHeaderPath, IFileSystemAccess.DEFAULT_OUTPUT,
                PreferenceConstantsSomeIP::NO_CODE)
            fileSystemAccess.generateFile(tc.someipDeploymentSourcePath, IFileSystemAccess.DEFAULT_OUTPUT,
                PreferenceConstantsSomeIP::NO_CODE)
        }
    }

    def private generateDeploymentHeader(FTypeCollection _tc,
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''
        «generateCommonApiSomeIPLicenseHeader()»

        #ifndef «_tc.defineName.toUpperCase»_SOMEIP_DEPLOYMENT_HPP_
        #define «_tc.defineName.toUpperCase»_SOMEIP_DEPLOYMENT_HPP_

        «val DeploymentHeaders = _tc.getDeploymentInputIncludes(_accessor)»
        «FOR deploymentHeader : DeploymentHeaders.sort»
            «IF !deploymentHeader.equals(someipDeploymentHeaderPath(_tc))»
                #include <«deploymentHeader»>
            «ENDIF»
        «ENDFOR»

        «startInternalCompilation»
        #include <CommonAPI/SomeIP/Deployment.hpp>
        «endInternalCompilation»

        «_tc.generateVersionNamespaceBegin»
        «_tc.model.generateNamespaceBeginDeclaration»
        «_tc.generateDeploymentNamespaceBegin»

        // typecollection-specific deployment types
        «FOR t: _tc.types.filter[it instanceof FEnumerationType]»
            «val deploymentType = t.generateDeploymentType(0, _accessor)»
            typedef «deploymentType» «t.elementName»Deployment_t;

        «ENDFOR»
        «FOR t: _tc.types.filter[!(it instanceof FEnumerationType)]»
            «val deploymentType = t.generateDeploymentType(0, _accessor)»
            typedef «deploymentType» «t.elementName»Deployment_t;

        «ENDFOR»

        // typecollection-specific deployments
        «FOR t: _tc.types»
            «t.generateDeploymentDeclaration(_tc, _accessor)»
        «ENDFOR»

        «_tc.generateDeploymentNamespaceEnd»
        «_tc.model.generateNamespaceEndDeclaration»
        «_tc.generateVersionNamespaceEnd»

        #endif // «_tc.defineName.toUpperCase»_SOMEIP_DEPLOYMENT_HPP_
    '''

    def private generateDeploymentSource(FTypeCollection _tc,
                                         PropertyAccessor _accessor,
                                         IResource _modelid) '''

        «generateCommonApiSomeIPLicenseHeader()»
        «val DeploymentHeaders = _tc.getDeploymentInputIncludes(_accessor)»
        «DeploymentHeaders.map["#include <" + it + ">"].join("\n")»

        «_tc.generateVersionNamespaceBegin»
        «_tc.model.generateNamespaceBeginDeclaration»
        «_tc.generateDeploymentNamespaceBegin»

        // typecollection-specific deployments
        «FOR t: _tc.types»
            «t.generateDeploymentDefinition(_tc, _accessor)»
        «ENDFOR»

        «_tc.generateDeploymentNamespaceEnd»
        «_tc.model.generateNamespaceEndDeclaration»
        «_tc.generateVersionNamespaceEnd»
    '''

    // Generate deployment types
    def protected dispatch String generateDeploymentType(FArrayType _array, int _indent, PropertyAccessor _accessor) {
        return generateArrayDeploymentType(_array.elementType, _indent, _accessor)
    }

    def protected String generateArrayDeploymentType(FTypeRef _elementType, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent) + "CommonAPI::SomeIP::ArrayDeployment<\n"
        if (_elementType.derived !== null) {
            deployment += generateDeploymentType(_elementType.derived, _indent + 1, _accessor)
        } else if (_elementType.interval !== null) {
            deployment += generateDeploymentType(_elementType.interval, _indent + 1, _accessor)
        } else if (_elementType.predefined !== null) {
            deployment += generateDeploymentType(_elementType.predefined, _indent + 1, _accessor)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }

    def protected dispatch String generateDeploymentType(FEnumerationType _enum, int _indent, PropertyAccessor _accessor) {
        if (_indent == 0)
            return generateIndent(_indent) + "CommonAPI::SomeIP::EnumerationDeployment<"
                 + _enum.getBackingType(_accessor).toString.toLowerCase + "_t>"
        else
            return generateIndent(_indent) + _enum.getDeploymentType(_enum.containingTypeCollection, true)
    }

    def protected dispatch String generateDeploymentType(FMapType _map, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent) + "CommonAPI::SomeIP::MapDeployment<\n"
        if (_map.keyType.derived !== null) {
            deployment += generateDeploymentType(_map.keyType.derived, _indent + 1, _accessor)
        } else if (_map.keyType.interval !== null) {
            deployment += generateDeploymentType(_map.keyType.interval, _indent + 1, _accessor)
        } else if (_map.keyType.predefined !== null) {
            deployment += generateDeploymentType(_map.keyType.predefined, _indent + 1, _accessor)
        }
        deployment += ",\n"
        if (_map.valueType.derived !== null) {
            deployment += generateDeploymentType(_map.valueType.derived, _indent + 1, _accessor)
        } else if (_map.valueType.interval !== null) {
            deployment += generateDeploymentType(_map.valueType.interval, _indent + 1, _accessor)
        } else if (_map.valueType.predefined !== null) {
            deployment += generateDeploymentType(_map.valueType.predefined, _indent + 1, _accessor)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }

    def protected dispatch String generateDeploymentType(FIntegerInterval _interval, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent)
        deployment += "CommonAPI::SomeIP::IntegerDeployment<int32_t>"
        return deployment;
    }

    def protected dispatch String generateDeploymentType(FStructType _struct, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _struct.allElements
        if (elements.length == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::SomeIP::StructDeployment<\n"
            for (e : elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1, overwriteAccessor)
                } else if (e.type.derived !== null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1, overwriteAccessor)
                } else if (e.type.interval !== null) {
                    deployment = deployment + generateDeploymentType(e.type.interval, _indent + 1, overwriteAccessor)
                } else if (e.type.predefined !== null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1, overwriteAccessor)
                } else {
                   deployment += "Warning struct with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }

    def protected dispatch String generateDeploymentType(FUnionType _union, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _union.allElements
        if (elements == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::SomeIP::VariantDeployment<\n"
            for (e : elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1, overwriteAccessor)
                } else if (e.type.derived !== null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1, overwriteAccessor)
                } else if (e.type.interval !== null) {
                    deployment = deployment + generateDeploymentType(e.type.interval, _indent + 1, overwriteAccessor)
                } else if (e.type.predefined !== null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1, overwriteAccessor)
                } else {
                   deployment += "Warning union with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }

    def protected dispatch String generateDeploymentType(FTypeDef _typeDef, int _indent, PropertyAccessor _accessor) {
        val FTypeRef actualType = _typeDef.actualType
        if (actualType.derived !== null)
            return actualType.derived.generateDeploymentType(_indent, _accessor)
        if (actualType.interval !== null)
            return actualType.interval.generateDeploymentType(_indent, _accessor)
        if (actualType.predefined !== null)
            return actualType.predefined.generateDeploymentType(_indent, _accessor)

        return "CommonAPI::EmptyDeployment"
    }

    def protected dispatch String generateDeploymentType(FBasicTypeId _type, int _indent, PropertyAccessor _accessor) {
        var String deployment = generateIndent(_indent)
        if (_type == FBasicTypeId.STRING)
            deployment = deployment + "CommonAPI::SomeIP::StringDeployment"
        else if (_type == FBasicTypeId.BYTE_BUFFER)
            deployment = deployment + "CommonAPI::SomeIP::ByteBufferDeployment"
        else if (_type == FBasicTypeId.INT8 || _type == FBasicTypeId.INT16 ||
            _type == FBasicTypeId.INT32 || _type == FBasicTypeId.INT64 ||
            _type == FBasicTypeId.UINT8 || _type == FBasicTypeId.UINT16 ||
            _type == FBasicTypeId.UINT32 || _type == FBasicTypeId.UINT64)
            deployment = deployment + _type.deployment
        else
            deployment = deployment + "CommonAPI::EmptyDeployment"

        return deployment
    }

    def protected dispatch String generateDeploymentType(FType _type, int _indent, PropertyAccessor _accessor) {
        return generateIndent(_indent) + "CommonAPI::EmptyDeployment"
    }

    //////////////////////////////////////
    // Generate deployment declarations //
    //////////////////////////////////////
    def protected dispatch String generateDeploymentDeclaration(FArrayType _array, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            return _array.elementType.generateDeploymentDeclaration(_tc, _accessor) +
                   "COMMONAPI_EXPORT extern " + _array.getDeploymentType(_tc, true) + " " + _array.name + "Deployment;"
        }
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_enum)) {
            return "COMMONAPI_EXPORT extern " + _enum.elementName + "Deployment_t " + _enum.name + "Deployment;"
        }
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            return _map.keyType.generateDeploymentDeclaration(_tc, _accessor) +
                   _map.valueType.generateDeploymentDeclaration(_tc, _accessor) +
                   "COMMONAPI_EXPORT extern " + _map.getDeploymentType(_tc, true) + " " + _map.name + "Deployment;"
        }
    }

    def protected dispatch String generateDeploymentDeclaration(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        if(_struct.isStructEmpty ) {
            return "static_assert(false, \"struct " + _struct.name + " must not be empty !\");";
        }
        if (_accessor.hasDeployment(_struct)) {
            var String declaration = ""
            for (e : _struct.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                declaration += e.generateDeploymentDeclaration(_tc, overwriteAccessor)
            }
            declaration += "COMMONAPI_EXPORT extern " + _struct.getDeploymentType(_tc, true) + " " + _struct.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_union)) {
            var String declaration = ""
            for (e : _union.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                declaration += e.generateDeploymentDeclaration(_tc, overwriteAccessor)
            }
            declaration += "COMMONAPI_EXPORT extern " + _union.getDeploymentType(_tc, true) + " " + _union.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FField _field, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_field) || (_field.array && _accessor.hasDeployment(_field))) {
            // remove rightmost '_' for compatibility's sake
            var String accessorName = _accessor.name
            if (_accessor.name.length > 0)
                accessorName = _accessor.name.substring(0, _accessor.name.length() - 1)
            return "COMMONAPI_EXPORT extern " + _field.getDeploymentType(_tc, true) + " " + accessorName + "Deployment;\n"
        }
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }

    def protected dispatch String generateDeploymentDeclaration(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }

    /////////////////////////////////////
    // Generate deployment definitions //
    /////////////////////////////////////
    def protected dispatch String generateDeploymentDefinition(FArrayType _array, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(_array)
            var String definition = _array.elementType.generateDeploymentDefinition(_tc, overwriteAccessor)
            if (_accessor.parent === null) {
                definition += _array.getDeploymentType(_tc, true) + " " + _accessor.name + _array.name + "Deployment("
                definition += _array.getDeploymentParameter(_array, _tc, _accessor)
                definition += ");\n"
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
            if (_accessor.hasDeployment(_enum) && _accessor.parent === null) {
                var String definition = _enum.elementName + "Deployment_t " + _accessor.name + _enum.name + "Deployment("
                definition += _enum.getDeploymentParameter(_enum, _tc, _accessor)
                definition += ");\n"
                return definition
            }
            return ""
    }

    def protected dispatch String generateDeploymentDefinition(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            var String definition = _map.keyType.generateDeploymentDefinition(_tc, _accessor) +
                                    _map.valueType.generateDeploymentDefinition(_tc, _accessor)
            // Generate if top level element or has overriden key/value
            if (_accessor.parent === null || definition != "") {
                definition += _map.getDeploymentType(_tc, true) + " " + _accessor.name + _map.name + "Deployment("
                definition += _map.getDeploymentParameter(_map, _tc, _accessor)
                definition += ");\n"
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_struct)) {
            for (e : _struct.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentDefinition(_tc, overwriteAccessor)
            }
            // Generate if struct is top-level or has overridden field 
            if (_accessor.parent === null || definition != "") {
                definition += _struct.getDeploymentType(_tc, true) + " " + _accessor.name + _struct.name + "Deployment("
                definition += _struct.getDeploymentParameter(_struct, _tc, _accessor)
                definition += ");\n"
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_union)) {
            for (e : _union.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentDefinition(_tc, overwriteAccessor)
            }
            // Generate if union is top-level or has overridden field
            if (_accessor.parent === null || definition != "") {
                definition += _union.getDeploymentType(_tc, true) + " " + _accessor.name + _union.name + "Deployment("
                definition += _union.getDeploymentParameter(_union, _tc, _accessor)
                definition += ");\n"
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FField _field, FTypeCollection _tc, PropertyAccessor _accessor) {
       if (_accessor.hasSpecificDeployment(_field) ||
           (_field.array && _accessor.hasDeployment(_field))) {
            var String definition = "";
            var String accessorName = _accessor.name
            if (_accessor.name.length > 0)
                accessorName = _accessor.name.substring(0, _accessor.name.length() - 1)

            definition += _field.type.generateDeploymentDefinition(_tc, _accessor)
            if (_field.array && _accessor.hasNonArrayDeployment(_field)) {
                definition += _field.type.getDeploymentType(_tc, false) + " " + accessorName + "ElementDeployment("
                definition += getDeploymentParameter(_field.type, _field, _tc, _accessor)
                definition += ");\n";
            }
            definition += _field.getDeploymentType(_tc, true) + " " + accessorName + "Deployment("
            if (_field.array && _accessor.hasNonArrayDeployment(_field)) {
                definition += "&" + accessorName + "ElementDeployment, "
                definition += getArrayDeploymentParameter(_field.type, _field, _tc, _accessor)
            } else {
                definition += getDeploymentParameter(_field, _field, _tc, _accessor)
            }
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.isProperOverwrite())
            if (_typeRef.derived !== null) {
                return generateDeploymentDefinition(_typeRef.derived, _tc, _accessor)
            }
        return ""
    }
    def protected dispatch String generateDeploymentParameterDefinition(FArrayType _array, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(_array)
            var String definition = _array.elementType.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            definition += _array.getDeploymentType(_tc, true) + " " + _accessor.name + _array.name + "Deployment("
            definition += _array.getDeploymentParameter(_array, _tc, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
            if (_accessor.hasDeployment(_enum)) {
                var String definition = (_enum.eContainer() as FModelElement).fullName + "_::" + _enum.name + "Deployment_t " + _accessor.name + _enum.name + "Deployment("
                definition += _enum.getDeploymentParameter(_enum, _tc, _accessor)
                definition += ");\n"
                return definition
            }
            return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            var String definition = _map.keyType.generateDeploymentParameterDefinition(_tc, _accessor) +
                                    _map.valueType.generateDeploymentParameterDefinition(_tc, _accessor)
            definition += _map.getDeploymentType(_tc, true) + " " + _accessor.name + _map.name + "Deployment("
            definition += _map.getDeploymentParameter(_map, _tc, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_struct)) {
            for (e : _struct.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            }
            definition += _struct.getDeploymentType(_tc, true) + " " + _accessor.name + _struct.name + "Deployment("
            definition += _struct.getDeploymentParameter(_struct, _tc, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_union)) {
            for (e : _union.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            }
            definition += _union.getDeploymentType(_tc, true) + " " + _accessor.name + _union.name + "Deployment("
            definition += _union.getDeploymentParameter(_union, _tc, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FField _field, FTypeCollection _tc, PropertyAccessor _accessor) {
       if (_accessor.hasSpecificDeployment(_field) ||
           (_field.array && _accessor.hasDeployment(_field))) {
            var String definition = _field.type.generateDeploymentParameterDefinitions(_tc, _accessor)
            // remove rightmost '_' for compatibility's sake
            var String accessorName = _accessor.name
            if (_accessor.name.length > 0)
                accessorName = _accessor.name.substring(0, _accessor.name.length() - 1)
            if (_field.array && _accessor.hasNonArrayDeployment(_field)) {
                definition += _field.type.getDeploymentType(_tc, false) + " " + accessorName + "ElementDeployment("
                definition += getDeploymentParameter(_field.type, _field, _tc, _accessor)
                definition += ");\n";
            }
            definition += _field.getDeploymentType(_tc, true) + " " + accessorName + "Deployment("
            if (_field.array && _accessor.hasNonArrayDeployment(_field)) {
                definition += "&" + accessorName + "ElementDeployment, "
                definition += getArrayDeploymentParameter(_field.type, _field, _tc, _accessor)
            } else {
                definition += getDeploymentParameter(_field, _field, _tc, _accessor)
            }
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinition(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return generateDeploymentParameterDefinition(_typeDef.getActualType, _tc, _accessor)
    }

    def protected dispatch String generateDeploymentParameterDefinition(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_typeRef.derived !== null) {
            return generateDeploymentParameterDefinition(_typeRef.derived, _tc, _accessor)
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FArrayType _array, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(_array)
            var String definition = _array.elementType.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
            return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            var String definition = _map.keyType.generateDeploymentParameterDefinition(_tc, _accessor) +
                                    _map.valueType.generateDeploymentParameterDefinition(_tc, _accessor)
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_struct)) {
            for (e : _struct.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_union)) {
            for (e : _union.elements) {
                var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(e)
                definition += e.generateDeploymentParameterDefinition(_tc, overwriteAccessor)
            }
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return generateDeploymentParameterDefinitions(_typeDef.getActualType, _tc, _accessor)
    }

    def protected dispatch String generateDeploymentParameterDefinitions(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_typeRef.derived !== null) {
            return generateDeploymentParameterDefinitions(_typeRef.derived, _tc, _accessor)
        }
        return ""
    }

    ///////////////////////////////////
    // Get the deployment parameter  //
    ///////////////////////////////////
    def protected dispatch String getDeploymentParameter(FArrayType _array, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(_array)
        var String parameter = getArrayElementTypeDeploymentParameter(_array.elementType, _source, _tc, overwriteAccessor) + ", "
        parameter += getArrayDeploymentParameter(_array, _source, _tc, _accessor)
        return parameter
    }

    def protected dispatch String getDeploymentParameter(FEnumerationType _enum, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""

        var Integer baseType = _accessor.getSomeIpEnumWidthHelper(_source)
        if (baseType === null)
            baseType = _accessor.getSomeIpEnumWidth(_enum)

        var Integer bitWidth = _accessor.getSomeIpEnumBitWidthHelper(_source)
        if (bitWidth === null)
            bitWidth = _accessor.getSomeIpEnumBitWidthHelper(_enum)

        if (bitWidth !== null) {
            parameter += bitWidth.toString
        } else {
            if (baseType !== null) {
                val int bits = baseType.intValue * 8
                parameter += Integer.toString(bits)
            } else {
                parameter += "8" // Default value: 1 Byte
            }
        }

        val FBasicTypeId typeId = _enum.getBackingType(_accessor)
        parameter += ", " + isSigned(typeId.literal)

        var Integer invalidValue = _accessor.getSomeIpEnumInvalidValueHelper(_source)
        if (invalidValue === null)
            invalidValue = _accessor.getSomeIpEnumInvalidValue(_enum)
        if (invalidValue !== null)
            parameter += ", " + invalidValue.toString

        return parameter
    }

    def protected dispatch String getDeploymentParameter(FMapType _map, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = _map.keyType.getDeploymentRef(null, _accessor) + ", " + _map.valueType.getDeploymentRef(null, _accessor) + ", "
        parameter += getMapDeploymentParameter(_map, _source, _tc, _accessor)
        return parameter
    }

    def protected dispatch String getDeploymentParameter(FIntegerInterval _interval, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""
        var Integer bitWidth = _accessor.getSomeIpIntegerBitWidthHelper(_source)
        if (bitWidth !== null)
            parameter += bitWidth.toString
        else
            parameter += 32
        val Integer invalidValue = _accessor.getSomeIpIntegerInvalidValueHelper(_source)
        if (invalidValue !== null) {
            parameter += ", " + invalidValue.toString
        }
        return parameter
    }

    def protected dispatch String getDeploymentParameter(FStructType _struct, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""

        var Integer lengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_struct)
        if (lengthWidth !== null)
            parameter += lengthWidth.toString + ", "
        else
            parameter += "0, "
            

        parameter += getDerivedDeploymentParameter(_struct, _tc, _accessor)
        // cut off the last comma
        return parameter.substring(0, parameter.length -2)
    }

    def protected String getDerivedDeploymentParameter(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""

        if(_struct.base !== null) { // need to use the accessor for the base struct !
            var baseAccessor = getSomeIpAccessor(_struct.base.eContainer as FTypeCollection)
            parameter += getDerivedDeploymentParameter(_struct.base, _tc, baseAccessor)
        }
        for (s : _struct.elements) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(s);
            parameter += s.getDeploymentRef(_struct, _tc, overwriteAccessor) + ", "
        }
        return parameter
    }

    def protected dispatch String getDeploymentParameter(FUnionType _union, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""

        var Integer lengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_union)
        if (lengthWidth !== null)
            parameter += lengthWidth.toString + ", "
        else
            parameter += "4, "

        var Integer typeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_union)
        if (typeWidth !== null)
            parameter += typeWidth.toString + ", "
        else
            parameter += "4, "

        var Boolean defaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_union)
        if (defaultOrder !== null)
            parameter += defaultOrder.toString + ", "
        else
            parameter += "true, "

        var Integer maxLength = _accessor.getSomeIpUnionMaxLengthHelper(_union)
        if (maxLength !== null)
            parameter += maxLength.toString + ", "
        else
            parameter += "0, "

        for (s : _union.elements) {
            var PropertyAccessor overwriteAccessor = _accessor.getOverwriteAccessor(s);
            parameter += s.getDeploymentRef(_union, _tc, overwriteAccessor)
            if (s != _union.elements.last) parameter += ", "
        }

        return parameter
    }

    def protected dispatch String getDeploymentParameter(FBasicTypeId _typeId, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""
        if (_typeId == FBasicTypeId.STRING) {
            val Integer length = _accessor.getSomeIpStringLength(_source)
            if (length !== null)
                parameter += length.toString + ", "
            else
                parameter += "0, "

            val Integer lengthWidth = _accessor.getSomeIpStringLengthWidth(_source)
            if (lengthWidth !== null)
                parameter += lengthWidth.toString + ", "
            else
                parameter += "4, "

            val PropertyAccessor.SomeIpStringEncoding encoding
                = _accessor.getSomeIpStringEncoding(_source)
            if (encoding !== null)
                parameter += "CommonAPI::SomeIP::StringEncoding::" + encoding.toString.toUpperCase
            else
                parameter += "CommonAPI::SomeIP::StringEncoding::UTF8"
        } else if (_typeId == FBasicTypeId.BYTE_BUFFER) {
            parameter += getByteBufferDeploymentParamter(_source, _source, _accessor)
        } else if (_typeId == FBasicTypeId.INT8 || _typeId == FBasicTypeId.INT16 ||
            _typeId == FBasicTypeId.INT32 || _typeId == FBasicTypeId.INT64 ||
            _typeId == FBasicTypeId.UINT8 || _typeId == FBasicTypeId.UINT16 ||
            _typeId == FBasicTypeId.UINT32 || _typeId == FBasicTypeId.UINT64) {
            var Integer bitWidth = _accessor.getSomeIpIntegerBitWidthHelper(_source)
            if (bitWidth !== null)
                parameter += bitWidth.toString
            else
                parameter += _typeId.bitWidth
            val Integer invalidValue = _accessor.getSomeIpIntegerInvalidValueHelper(_source)
            if (invalidValue !== null) {
                parameter += ", " + invalidValue.toString
            }
        }
        return parameter
    }

    def protected dispatch String getDeploymentParameter(FTypeRef _typeRef, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_typeRef.derived !== null) {
            return _typeRef.derived.getDeploymentParameter(_source, _tc, _accessor)
        }
        if (_typeRef.interval !== null) {
            return _typeRef.interval.getDeploymentParameter(_source, _tc, _accessor)
        }
        if (_typeRef.predefined !== null) {
            return _typeRef.predefined.getDeploymentParameter(_source, _tc, _accessor)
        }

        return ""
    }

    def protected dispatch String getDeploymentParameter(FTypeDef _typeDef, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {

        return _typeDef.getActualType.getDeploymentParameter(_source, _tc, _accessor)
    }


    def protected dispatch String getDeploymentParameter(FTypedElement _attribute, EObject _object, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_attribute.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_attribute.type, _object, _tc, _accessor) + ", "
            parameter += getArrayDeploymentParameter(_attribute, _attribute, _tc, _accessor)
            return parameter
        }
        return _attribute.type.getDeploymentParameter(_attribute, _tc, _accessor)
    }

    def protected dispatch String getDeploymentParameter(FArgument _argument, EObject _object, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_argument.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_argument.type, _object, _tc, _accessor) + ", "
            parameter += getArrayDeploymentParameter(_argument, _argument, _tc, _accessor)
            return parameter
        }
        return _argument.type.getDeploymentParameter(_argument, _tc, _accessor)
    }

    // Arrays may be either defined types or inline
    def protected String getArrayElementTypeDeploymentParameter(FTypeRef _elementType, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        return _elementType.getDeploymentRef(_tc, _accessor)
    }

    def protected String getByteBufferDeploymentParamter(EObject _buffer, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        var Integer minLength = _accessor.getSomeIpByteBufferMinLength(_source)
        if (minLength === null && _buffer != _source)
            minLength = _accessor.getSomeIpByteBufferMinLength(_buffer)
        if (minLength !== null)
            parameter += minLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MIN_LENGTH.toString + ", "

        var Integer maxLength = _accessor.getSomeIpByteBufferMaxLength(_source)
        if (maxLength === null && _buffer != _source)
            maxLength = _accessor.getSomeIpByteBufferMaxLength(_buffer)
        if (maxLength !== null)
            parameter += maxLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MAX_LENGTH.toString + ", "

        var Integer lengthWidth = _accessor.getSomeIpByteBufferLengthWidth(_source)
        if (lengthWidth === null && _buffer != _source)
            lengthWidth = _accessor.getSomeIpByteBufferLengthWidth(_buffer)
        if (lengthWidth !== null)
            parameter += lengthWidth.toString
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_LENGTH_WIDTH.toString

        return parameter
    }

    def protected String getArrayDeploymentParameter(EObject _array, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""
        var Integer minLength = _accessor.getSomeIpArrayMinLengthHelper(_source)
        if (minLength === null && _array != _source)
            minLength = _accessor.getSomeIpArrayMinLengthHelper(_array)
        if (minLength !== null)
            parameter += minLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MIN_LENGTH.toString + ", "          

        var Integer maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_source)
        if (maxLength === null && _array != _source)
            maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_array)
        if (maxLength !== null)
            parameter += maxLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MAX_LENGTH.toString + ", "           

        var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_source)
        if (lengthWidth === null && _array != _source)
            lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_array)
        if (lengthWidth !== null)
            parameter += lengthWidth.toString
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_LENGTH_WIDTH.toString

        return parameter
    }

    def protected String getMapDeploymentParameter(EObject _map, EObject _source, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String parameter = ""
        var Integer minLength = _accessor.getSomeIpMapMinLengthHelper(_source)
        if (minLength === null && _map != _source)
            minLength = _accessor.getSomeIpMapMinLengthHelper(_map)
        if (minLength !== null)
            parameter += minLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MIN_LENGTH.toString            

        var Integer maxLength = _accessor.getSomeIpMapMaxLengthHelper(_source)
        if (maxLength === null && _map != _source)
            maxLength = _accessor.getSomeIpMapMaxLengthHelper(_map)
        if (maxLength !== null)
            parameter += maxLength.toString + ", "
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_MAX_LENGTH.toString + ", "          

        var Integer lengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_source)
        if (lengthWidth === null && _map != _source)
            lengthWidth = _accessor.getSomeIpMapLengthWidthHelper(_map)
        if (lengthWidth !== null)
            parameter += lengthWidth.toString
        else
            parameter += FrancaSomeIPDeploymentAccessorHelper.SOMEIP_DEFAULT_LENGTH_WIDTH.toString + ", "           

        return parameter
    }

}
