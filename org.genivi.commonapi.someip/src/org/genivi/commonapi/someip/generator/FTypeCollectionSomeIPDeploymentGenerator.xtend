/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

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

class FTypeCollectionSomeIPDeploymentGenerator {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPGeneratorExtensions
    @Inject private extension FrancaSomeIPDeploymentAccessorHelper
    
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
        
        #if !defined (COMMONAPI_INTERNAL_COMPILATION)
        #define COMMONAPI_INTERNAL_COMPILATION
        #endif
        #include <CommonAPI/SomeIP/Deployment.hpp>
        #undef COMMONAPI_INTERNAL_COMPILATION
        
        «_tc.generateVersionNamespaceBegin»
        «_tc.model.generateNamespaceBeginDeclaration»
        «_tc.generateDeploymentNamespaceBegin»
        
        // typecollection-specific deployment types
        «FOR t: _tc.types»
            «val deploymentType = t.generateDeploymentType(0)»
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
    def protected dispatch String generateDeploymentType(FArrayType _array, int _indent) {
        return generateArrayDeploymentType(_array.elementType, _indent)
    }
    
    def protected String generateArrayDeploymentType(FTypeRef _elementType, int _indent) {    
        var String deployment = generateIndent(_indent) + "CommonAPI::SomeIP::ArrayDeployment<\n"
        if (_elementType.derived != null) {
            deployment += generateDeploymentType(_elementType.derived, _indent + 1)
        } else if (_elementType.predefined != null) {
            deployment += generateDeploymentType(_elementType.predefined, _indent + 1)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }
    
    def protected dispatch String generateDeploymentType(FEnumerationType _enum, int _indent) {
    	return generateIndent(_indent) + "CommonAPI::SomeIP::EnumerationDeployment"
    }
    
    def protected dispatch String generateDeploymentType(FMapType _map, int _indent) {
        var String deployment = generateIndent(_indent) + "CommonAPI::MapDeployment<\n"
        if (_map.keyType.derived != null) {
            deployment += generateDeploymentType(_map.keyType.derived, _indent + 1)
        } else if (_map.keyType.predefined != null) {
            deployment += generateDeploymentType(_map.keyType.predefined, _indent + 1)
        }
        deployment += ",\n"
        if (_map.valueType.derived != null) {
            deployment += generateDeploymentType(_map.valueType.derived, _indent + 1)
        } else if (_map.valueType.predefined != null) {
            deployment += generateDeploymentType(_map.valueType.predefined, _indent + 1)
        }
        return deployment + "\n" + generateIndent(_indent) + ">"
    }
    
    def protected dispatch String generateDeploymentType(FStructType _struct, int _indent) {
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _struct.allElements
        if (elements.length == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::SomeIP::StructDeployment<\n"
            for (e : elements) {
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1)
                } else if (e.type.derived != null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1)
                } else if (e.type.predefined != null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1)
                } else {
                   deployment += "Warning struct with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }
    
    def protected dispatch String generateDeploymentType(FUnionType _union, int _indent) {
        var String deployment = generateIndent(_indent)
        var List<FField> elements = _union.allElements
        if (elements == 0) {
            deployment += "CommonAPI::EmptyDeployment"
        } else {
            deployment += "CommonAPI::SomeIP::VariantDeployment<\n"
            for (e : elements) {
                if (e.array) {
                    deployment = deployment + generateArrayDeploymentType(e.type, _indent + 1)
                } else if (e.type.derived != null) {
                    deployment = deployment + generateDeploymentType(e.type.derived, _indent + 1)
                } else if (e.type.predefined != null) {
                    deployment = deployment + generateDeploymentType(e.type.predefined, _indent + 1)
                } else {
                   deployment += "Warning union with unknown element: " + e.type.fullName
                }
                if (e != elements.last) deployment += ",\n"
            }
            deployment += "\n" + generateIndent(_indent) + ">"
        }
        return deployment
    }
    
    def protected dispatch String generateDeploymentType(FTypeDef _typeDef, int _indent) {
        val FTypeRef actualType = _typeDef.actualType
        if (actualType.derived != null)
            return actualType.derived.generateDeploymentType(_indent)
            
        if (actualType.predefined != null)
            return actualType.predefined.generateDeploymentType(_indent)
            
        return "CommonAPI::EmptyDeployment"
    }
    
    def protected dispatch String generateDeploymentType(FBasicTypeId _type, int _indent) {
        var String deployment = generateIndent(_indent)
        if (_type == FBasicTypeId.STRING)
            deployment = deployment + "CommonAPI::SomeIP::StringDeployment"
        else if (_type == FBasicTypeId.BYTE_BUFFER)
            deployment = deployment + "CommonAPI::SomeIP::ArrayDeployment<CommonAPI::EmptyDeployment>"
        else
            deployment = deployment + "CommonAPI::EmptyDeployment"

        return deployment
    }
    
    def protected dispatch String generateDeploymentType(FType _type, int _indent) {
        return generateIndent(_indent) + "CommonAPI::EmptyDeployment"   
    }
    
    /////////////////////////////////////
    // Generate deployment declarations //
    /////////////////////////////////////
    def protected dispatch String generateDeploymentDeclaration(FArrayType _array, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_array)) {
            return _array.elementType.generateDeploymentDeclaration(_tc, _accessor) + 
                   "extern " + _array.getDeploymentType(_tc, true) + " " + _array.name + "Deployment;"
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDeclaration(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_enum)) {
            return "extern " + _enum.elementName + "Deployment_t " + _enum.name + "Deployment;"
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDeclaration(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            return _map.keyType.generateDeploymentDeclaration(_tc, _accessor) +
                   _map.valueType.generateDeploymentDeclaration(_tc, _accessor) +
                   "extern " + _map.getDeploymentType(_tc, true) + " " + _map.name + "Deployment;"
        }
    }
    
    def protected dispatch String generateDeploymentDeclaration(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_struct)) {
            var String declaration = ""
            for (structElement : _struct.elements) {
                declaration += structElement.generateDeploymentDeclaration(_tc, _accessor)
            }
            declaration += "extern " + _struct.getDeploymentType(_tc, true) + " " + _struct.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDeclaration(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_union)) {
            var String declaration = ""
            for (structElement : _union.elements) {
                declaration += structElement.generateDeploymentDeclaration(_tc, _accessor)
            }
            declaration += "extern " + _union.getDeploymentType(_tc, true) + " " + _union.name + "Deployment;"
            return declaration + "\n"
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDeclaration(FField _field, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_field)) {
            return "extern " + _field.getDeploymentType(_tc, true) + " " + _field.getRelativeName() + "Deployment;\n" 
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
            var String definition = _array.elementType.generateDeploymentDefinition(_tc, _accessor)
            definition += _array.getDeploymentType(_tc, true) + " " + _array.name + "Deployment("
            definition += _array.getDeploymentParameter(_array, _accessor)
            definition += ");"
            return definition
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDefinition(FEnumerationType _enum, FTypeCollection _tc, PropertyAccessor _accessor) {
	        if (_accessor.hasDeployment(_enum)) {
	            var String definition = _enum.elementName + "Deployment_t " + _enum.name + "Deployment("
	            definition += _enum.getDeploymentParameter(_enum, _accessor)
	            definition += ");"
	            return definition
	        }
	        return ""
    }
    
    def protected dispatch String generateDeploymentDefinition(FMapType _map, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_map)) {
            var String definition = _map.keyType.generateDeploymentDefinition(_tc, _accessor) +
                                    _map.valueType.generateDeploymentDefinition(_tc, _accessor)
            definition += _map.getDeploymentType(_tc, true) + " " + _map.name + "Deployment("
            definition += _map.getDeploymentParameter(_map, _accessor)
            definition += ");"
            return definition
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDefinition(FStructType _struct, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_struct)) {
            for (structElement : _struct.elements) {
                if (_accessor.hasDeployment(structElement)) {
                    definition += structElement.getDeploymentType(_tc, true) + " " + structElement.relativeName + "Deployment("
                    definition += structElement.getDeploymentParameter(structElement, _accessor)
                    definition += ");\n"
                }
            }
            definition += _struct.getDeploymentType(_tc, true) + " " + _struct.name + "Deployment("
            definition += _struct.getDeploymentParameter(_struct, _accessor)
            definition += ");\n"        
            return definition
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDefinition(FUnionType _union, FTypeCollection _tc, PropertyAccessor _accessor) {
        var String definition = ""
        if (_accessor.hasDeployment(_union)) {
            for (unionElement : _union.elements) {
                if (_accessor.hasDeployment(unionElement)) {
                    definition += unionElement.getDeploymentType(_tc, true) + " " + unionElement.relativeName + "Deployment("
                    definition += unionElement.getDeploymentParameter(unionElement, _accessor)
                    definition += ");\n"
                }
            }
            definition += _union.getDeploymentType(_tc, true) + " " + _union.name + "Deployment("
            definition += _union.getDeploymentParameter(_union, _accessor)
            definition += ");\n"
            return definition
        }
        return ""
    }
    
    def protected dispatch String generateDeploymentDefinition(FField _field, FTypeCollection _tc, PropertyAccessor _accessor) {
       if (_accessor.hasSpecificDeployment(_field) ||
           _field.array && _accessor.hasDeployment(_field)) {
            var String definition = _field.getDeploymentType(_tc, true) + " " + _field.getRelativeName() + "Deployment("
            definition += getDeploymentParameter(_field.type, _field, _accessor)
            if (_field.array) {
                definition += getArrayElementTypeDeploymentParameter(_field.type, _field, _accessor) + ", "
                definition += getArrayDeploymentParameter(_field.type, _field, _accessor)
            } else {
                definition += getDeploymentParameter(_field.type, _field, _accessor)
            }                
            definition += ");\n"
            return definition
        }
        return ""
    }

    def protected dispatch String generateDeploymentDefinition(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return generateDeploymentDefinition(_typeDef.getActualType, _tc, _accessor)
    }
    
    def protected dispatch String generateDeploymentDefinition(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }

    ///////////////////////////////////
    // Get the deployment parameter  //
    ///////////////////////////////////    
    def protected dispatch String getDeploymentParameter(FArrayType _array, EObject _source, PropertyAccessor _accessor) {
        var String parameter = getArrayElementTypeDeploymentParameter(_array.elementType, _array, _accessor) + ", "
        parameter += getArrayDeploymentParameter(_array, _source, _accessor)
        return parameter
    }
    
    def protected dispatch String getDeploymentParameter(FEnumerationType _enum, EObject _source, PropertyAccessor _accessor) {
        val Integer baseType = _accessor.getSomeIpEnumWidth(_enum)
        if (baseType != null)
        	return baseType.toString
        return "4"
    }
    
    def protected dispatch String getDeploymentParameter(FMapType _map, EObject _source, PropertyAccessor _accessor) {
        return _map.keyType.getDeploymentRef(_accessor) + ", " + _map.valueType.getDeploymentRef(_accessor) 
    }
    
    def protected dispatch String getDeploymentParameter(FStructType _struct, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        
        var Integer lengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_source)
        if (lengthWidth == null && _struct != _source)
            lengthWidth = _accessor.getSomeIpStructLengthWidthHelper(_struct)
        if (lengthWidth != null)
            parameter += lengthWidth.toString + ", "
        else
            parameter += "4, "

        parameter += getDerivedDeploymentParameter(_struct, _accessor)
        // cut off the last comma
        return parameter.substring(0, parameter.length -2)
    }

    def protected String getDerivedDeploymentParameter(FStructType _struct, PropertyAccessor _accessor) {
        var String parameter = ""
        
        if(_struct.base != null) { // need to use the accessor for the base struct !
            var baseAccessor = getAccessor(_struct.base.eContainer as FTypeCollection)
            parameter += getDerivedDeploymentParameter(_struct.base, baseAccessor)
           
        }
        for (s : _struct.elements) {
            parameter += s.getDeploymentRef(_struct, _accessor) + ", "
        }   
        
        return parameter
    }
    
    def protected dispatch String getDeploymentParameter(FUnionType _union, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        
        var Integer lengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_source)
        if (lengthWidth == null && _union != _source)
            lengthWidth = _accessor.getSomeIpUnionLengthWidthHelper(_union)
        if (lengthWidth != null)
            parameter += lengthWidth.toString + ", "
        else
            parameter += "4, " 

        var Integer typeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_source)
        if (typeWidth == null && _union != _source)
            typeWidth = _accessor.getSomeIpUnionTypeWidthHelper(_union)
        if (typeWidth != null)
            parameter += typeWidth.toString + ", "
        else
            parameter += "4, " 

        var Boolean defaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_source)
        if (defaultOrder == null && _union != _source)
            defaultOrder = _accessor.getSomeIpUnionDefaultOrderHelper(_union)
        if (defaultOrder != null)
            parameter += defaultOrder.toString + ", "
        else
            parameter += "true, "

        var Integer maxLength = _accessor.getSomeIpUnionMaxLengthHelper(_source)
        if (maxLength == null && _union != _source)
            maxLength = _accessor.getSomeIpUnionMaxLengthHelper(_union)
        if (maxLength != null)
            parameter += maxLength.toString + ", "
        else
            parameter += "0, "

        for (s : _union.elements) {
            parameter += s.getDeploymentRef(_union, _accessor)
            if (s != _union.elements.last) parameter += ", "    
        }         

        return parameter
    }
    
    def protected dispatch String getDeploymentParameter(FBasicTypeId _typeId, EObject _source, PropertyAccessor _accessor) {
        var String parameter = ""
        if (_typeId == FBasicTypeId.STRING) {
            val Integer length = _accessor.getSomeIpStringLength(_source)
            if (length != null)
                parameter += length.toString + ", "
            else
                parameter += "0, "

            val Integer lengthWidth = _accessor.getSomeIpStringLengthWidth(_source)
            if (lengthWidth != null)
                parameter += lengthWidth.toString + ", "
            else 
                parameter += "4, "

            val PropertyAccessor.SomeIpStringEncoding encoding 
                = _accessor.getSomeIpStringEncoding(_source)
            if (encoding != null)
                parameter += "CommonAPI::SomeIP::StringEncoding::" + encoding.toString.toUpperCase
            else
                parameter += "CommonAPI::SomeIP::StringEncoding::UTF8"
        }
        else if (_typeId == FBasicTypeId.BYTE_BUFFER) {
            parameter += "static_cast<CommonAPI::EmptyDeployment*>(nullptr), " + getArrayDeploymentParameter(_source, _source, _accessor)   
        }
        return parameter
    }
    
    def protected dispatch String getDeploymentParameter(FTypeRef _typeRef, EObject _source, PropertyAccessor _accessor) {
        if (_typeRef.derived != null) {
            return _typeRef.derived.getDeploymentParameter(_source, _accessor)
        }
        
        if (_typeRef.predefined != null) {
            return _typeRef.predefined.getDeploymentParameter(_source, _accessor)
        }
        
        return ""
    }

    def protected dispatch String getDeploymentParameter(FTypeDef _typeDef, EObject _source, PropertyAccessor _accessor) {

        return getDeploymentParameter(_typeDef.getActualType, _source, _accessor)
    }

    
    def protected dispatch String getDeploymentParameter(FTypedElement _attribute, EObject _object, PropertyAccessor _accessor) {
        if (_attribute.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_attribute.type, _object, _accessor) + ", "
            parameter += getArrayDeploymentParameter(_attribute, _attribute, _accessor)
            return parameter
        }
        return _attribute.type.getDeploymentParameter(_attribute, _accessor)
    }

    def protected dispatch String getDeploymentParameter(FArgument _argument, EObject _object, PropertyAccessor _accessor) {
        if (_argument.array) {
            var String parameter = getArrayElementTypeDeploymentParameter(_argument.type, _object, _accessor) + ", "
            parameter += getArrayDeploymentParameter(_argument, _argument, _accessor)
            return parameter
        }
        return _argument.type.getDeploymentParameter(_argument, _accessor)
    }
    
    // Arrays may be either defined types or inline
    def protected String getArrayElementTypeDeploymentParameter(FTypeRef _elementType, EObject _source, PropertyAccessor _accessor) {
        return _elementType.getDeploymentRef(_accessor)
    } 

    def protected String getArrayDeploymentParameter(EObject _array, EObject _source, PropertyAccessor _accessor) { 
        var String parameter = ""
        var Integer minLength = _accessor.getSomeIpArrayMinLengthHelper(_source)
        if (minLength == null && _array != _source)
            minLength = _accessor.getSomeIpArrayMinLengthHelper(_array)
        if (minLength != null)    
            parameter += minLength.toString + ", "
        
        var Integer maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_source)
        if (maxLength == null && _array != _source)
            maxLength = _accessor.getSomeIpArrayMaxLengthHelper(_array)
        if (maxLength != null)
            parameter += maxLength.toString + ", "

        var Integer lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_source)
        if (lengthWidth == null && _array != _source)
            lengthWidth = _accessor.getSomeIpArrayLengthWidthHelper(_array)
        if (lengthWidth != null)
            parameter += lengthWidth.toString
        
        return parameter
    }
}

