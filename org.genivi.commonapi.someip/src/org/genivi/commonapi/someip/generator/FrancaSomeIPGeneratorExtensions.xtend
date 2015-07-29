/* Copyright (C) 2014, 2015 BMW Group
 * Author: Lutz Bichler (lutz.bichler@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import java.util.List
import java.util.Map
import java.util.Set
import javax.inject.Inject
import org.eclipse.emf.common.util.EList
import org.eclipse.emf.ecore.EObject
import org.franca.core.franca.FArgument
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FBroadcast
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMethod
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypedElement
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions
import org.genivi.commonapi.someip.deployment.PropertyAccessor

import static extension java.lang.Integer.*

class FrancaSomeIPGeneratorExtensions {
    @Inject private extension FrancaGeneratorExtensions
    @Inject private extension FrancaSomeIPDeploymentAccessorHelper

    private static Map<FTypeCollection, PropertyAccessor> accessors__ = new HashMap<FTypeCollection, PropertyAccessor>()

    def insertAccessor(FTypeCollection _tc, PropertyAccessor _pa) {
        accessors__.put(_tc, _pa)
    }

    def PropertyAccessor getAccessor(FTypeCollection _tc) {
    	// get the accessor that matches this interface (tc)
    	var access = accessors__.get(_tc)
    	if(access == null) {
    		// It may be the base interface for which we dont have an accessor,
    		// if it is define in another fidl file.
    		// We should have at least one property accessor, use this one
			var accessors = accessors__.values()
		   	if(!accessors.isEmpty()) {
    			access = accessors.get(0)
    			}
    	}

    	if(access == null) {
    		var String tcType = null
    		if(_tc instanceof FInterface) {
    			tcType = "interface " 
    		} 
    		else {
    			tcType = "type collection "
    		}
    		throw new IllegalArgumentException("Could not find a someip accessor for " + tcType + _tc.name)
    	}
        return access
    }    

	def addRequiredHeaders(FType fType, Collection<String> generatedHeaders) {
        generatedHeaders.add(fType.FTypeCollection.someipDeploymentHeaderPath)
    }

    def getFTypeCollection(FType fType) {
        fType.eContainer as FTypeCollection
    }

    def String someipDeploymentHeaderFile(FInterface fInterface) {
        return fInterface.elementName + "SomeIPDeployment.hpp"
    }

    def String someipDeploymentHeaderPath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipDeploymentHeaderFile
    }

    def String someipDeploymentSourceFile(FInterface fInterface) {
        return fInterface.elementName + "SomeIPDeployment.cpp"
    }

    def String someipDeploymentSourcePath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipDeploymentSourceFile
    }

    def String someipDeploymentHeaderFile(FTypeCollection _tc) {
        return _tc.elementName + "SomeIPDeployment.hpp"
    }

    def String someipDeploymentHeaderPath(FTypeCollection _tc) {
        return _tc.versionPathPrefix + _tc.model.directoryPath + '/' + _tc.someipDeploymentHeaderFile
    }

    def String someipDeploymentSourceFile(FTypeCollection _tc) {
        return _tc.elementName + "SomeIPDeployment.cpp"
    }

    def String someipDeploymentSourcePath(FTypeCollection _tc) {
        return _tc.versionPathPrefix + _tc.model.directoryPath + '/' + _tc.someipDeploymentSourceFile
    }

    def String someipProxyHeaderFile(FInterface fInterface) {
        return fInterface.elementName + "SomeIPProxy.hpp"
    }

    def String someipProxyHeaderPath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipProxyHeaderFile
    }

    def String someipProxySourceFile(FInterface fInterface) {
       return fInterface.elementName + "SomeIPProxy.cpp"
    }

    def String someipProxySourcePath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' + fInterface.someipProxySourceFile
    }

    def String someipProxyClassName(FInterface fInterface) {
        return fInterface.elementName + 'SomeIPProxy'
    }

    def String setMethodName(FAttribute _attribute) {
        return 'set' + _attribute.className
    }

    def String getMethodName(FAttribute _attribute) {
        return 'get' + _attribute.className
    }
    
    def String getName(FInterface fInterface, PropertyAccessor deploymentAccessor)
    {
        val name = fInterface.name

        if (null != name)
        {
            return '"' + name + '"'
        }
        else
        {
            return fInterface.elementName + "::getInterface()"
        }
    }

    def String getEventIdentifier(FBroadcast _broadcast, PropertyAccessor _accessor)
    {
        val Integer value = _accessor.getSomeIpEventID(_broadcast)
        if (value != null)
            return "0x" +  value.toHexString
        return "UNDEFINED_EVENT_ID"
    }

    def List<String> getEventGroups(FBroadcast _broadcast, PropertyAccessor _accessor)
    {
        val List<Integer> value = _accessor.getSomeIpEventGroups(_broadcast)
        if (value != null)
            return value.map[id|"0x" + id.toHexString] 

        var List<String> dummy = new ArrayList<String>
        dummy.add("UNDEFINED_EVENTGROUP_ID");
        return dummy
    }

    def String isReliable(FBroadcast _broadcast, PropertyAccessor _accessor)
    {
        val Boolean value = _accessor.getSomeIpReliable(_broadcast)
        if (value != null)
            return value.toString
        return "false"
    }

    def String getMethodIdentifier(FMethod _method, PropertyAccessor _accessor) 
    {
        val Integer value = _accessor.getSomeIpMethodID(_method)
        if (value != null)
            return "0x" + value.toHexString
        return "UNDEFINED_METHOD_ID"
    }

    def String isReliable(FMethod _method, PropertyAccessor _accessor)
    {
        val Boolean value = _accessor.getSomeIpReliable(_method)
        if (value != null)
            return value.toString
        return "false"
    }

    def String getGetterIdentifier(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Integer value = _accessor.getSomeIpGetterID(_attribute)
        if (value != null)
            return "0x" + value.toHexString
        return "UNDEFINED_GETTER_ID"
    }

    def String getSetterIdentifier(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Integer value = _accessor.getSomeIpSetterID(_attribute)
        if (value != null)
            return "0x" + value.toHexString
        return "UNDEFINED_SETTER_ID"
    }

    def String getNotifierIdentifier(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Integer value = _accessor.getSomeIpNotifierID(_attribute)
        if (value != null)
            return "0x" + value.toHexString
        return "UNDEFINED_GETTER_ID"

    }

    def List<String> getNotifierEventGroups(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val List<Integer> value = _accessor.getSomeIpEventGroups(_attribute)
        if (value != null)
            return value.map[id|"0x" + id.toHexString]
        
        var List<String> dummy = new ArrayList<String>()
        dummy.add("UNDEFINED_EVENTGROUP_ID")
        return dummy
    }

    def String isGetterReliable(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Boolean value = _accessor.getSomeIpGetterReliable(_attribute)
        if (value != null)
            return value.toString
        return "false"
    }

    def String isSetterReliable(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Boolean value = _accessor.getSomeIpSetterReliable(_attribute)
        if (value != null)
            return value.toString
        return "false"
    }

    def String isNotifyReliableAsString(FAttribute _attribute, PropertyAccessor _accessor)
    {
        val Boolean value = _accessor.getSomeIpNotifierReliable(_attribute)
        if (value != null)
            return value.toString
        return "false"
    }

    ////////////////////////////////////////
    // Get deployment type for an element //
    ////////////////////////////////////////
    def dispatch String getDeploymentType(FTypeDef _typeDef, FInterface _interface, boolean _useTc) {
        return _typeDef.actualType.getDeploymentType(_interface, _useTc)
    }
    
    def dispatch String getDeploymentType(FTypedElement _typedElement, FInterface _interface, boolean _useTc) {
        if (_typedElement.array)
            return "CommonAPI::SomeIP::ArrayDeployment<" + _typedElement.type.getDeploymentType(_interface, _useTc) + ">" 
        return _typedElement.type.getDeploymentType(_interface, _useTc)
    }
    
    def dispatch String getDeploymentType(FTypeRef _typeRef, FInterface _interface, boolean _useTc) {
        if (_typeRef.derived != null)
            return _typeRef.derived.getDeploymentType(_interface, _useTc)
       
        if (_typeRef.predefined != null)
            return _typeRef.predefined.getDeploymentType(_interface, _useTc)
            
        return "CommonAPI::EmptyDeployment"
    }

    def dispatch String getDeploymentType(FBasicTypeId _type, FInterface _interface, boolean _useTc) {
        if (_type == FBasicTypeId.STRING)
            return "CommonAPI::SomeIP::StringDeployment"
       return "CommonAPI::EmptyDeployment"
    }
    
    def dispatch String getDeploymentType(FEnumerationType _enum, FInterface _interface, boolean _useTc) {
        return "CommonAPI::SomeIP::EnumerationDeployment"
    }
    
    def dispatch String getDeploymentType(FType _type, FInterface _interface, boolean _useTc) {
        var String deploymentType = ""
        
        if (_useTc) {
        	if (_type.eContainer instanceof FTypeCollection && !(_type.eContainer instanceof FInterface)) {
        		deploymentType += (_type.eContainer as FModelElement).getElementName(_interface, false) + "_::"
        	}
        	else if (_interface != null) {
        		deploymentType += _interface.getElementName(_interface, false) + "_::"
        	}
        }
        else if (_interface != null) {
        	deploymentType += _interface.getElementName(_interface, false) + "_::"
        }

        deploymentType += _type.name + "Deployment_t"
    }

    ////////////////////////////////////////
    // Get deployment type for an element //
    ////////////////////////////////////////
    def String getDeploymentName(FTypedElement _typedElement, FModelElement _element, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_typedElement)) {
            var String deployment = ""
            if (_element != null) {
                val container = _element.eContainer()
                if (container instanceof FTypeCollection) {
                    deployment += container.getElementName(_interface, false) + "_::"
                }
                deployment += _element.name + "_"
            } else {
                val container = _typedElement.eContainer()
                if (container instanceof FTypeCollection) {
                    deployment += container.getElementName(_interface, false) + "_::"
                }
            }
            deployment += _typedElement.name + "Deployment"
            return deployment
        } else {
            return _typedElement.type.getDeploymentName(_interface, _accessor)
        }
    }
    
    def dispatch String getDeploymentName(FTypeDef _typeDef, FInterface _interface, PropertyAccessor _accessor) {
        return _typeDef.actualType.getDeploymentName(_interface, _accessor)
    }

    def dispatch String getDeploymentName(FTypeRef _typeRef, FInterface _interface, PropertyAccessor _accessor) {
        if (_typeRef.derived != null) {
            return _typeRef.derived.getDeploymentName(_interface, _accessor)
        }
        return _typeRef.predefined.getDeploymentName(_interface, _accessor)
    }

    def dispatch String getDeploymentName(FType _type, FInterface _interface, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_type)) {
            var String name = ""
            val EObject container = _type.eContainer()
            if (container instanceof FTypeCollection) {
                name += (container as FTypeCollection).getElementName(_interface, false) + "_::"
            }
            name += _type.name + "Deployment"
            return name
        }
        return ""
    }

    def dispatch String getDeploymentName(FBasicTypeId _typeId, FInterface _interface, PropertyAccessor _accessor) {
        return ""
    }

    ///////////////////////////////////////////////////////////
    // Get reference (C++ pointer) to a deployment parameter //
    ///////////////////////////////////////////////////////////
    def String getDeploymentRef(FTypedElement _typedElement, boolean _isArray, FModelElement _element, FInterface _interface, PropertyAccessor _accessor) {
        val String name = _typedElement.getDeploymentName(_element, _interface, _accessor)
        if (name != "")
            return "&" + name

        var String deployment = "static_cast<"
        deployment += _typedElement.getDeploymentType(_interface, true)
        deployment += "*>(nullptr)"
        return deployment
    }

    def String getDeploymentRef(FTypeRef _typeRef, FInterface _interface, PropertyAccessor _accessor) {
        val String name = _typeRef.getDeploymentName(_interface, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _typeRef.getDeploymentType(_interface, true) + "*>(nullptr)"
    }
    
    def String getDeploymentRef(FType _type, FInterface _interface, PropertyAccessor _accessor) {
        val String name = _type.getDeploymentName(_interface, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _type.getDeploymentType(_interface, true) + "*>(nullptr)"
    }
    
    def String getDeploymentRef(FBasicTypeId _typeId, FInterface _interface, PropertyAccessor _accessor) {
        val String name = _typeId.getDeploymentName(_interface, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _typeId.getDeploymentType(_interface, true) + "*>(nullptr)"
    }
    
    def String getErrorDeploymentRef(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        var String name = ""
        if ( _method.errorEnum != null) {
            name += _method.errorEnum.getDeploymentName(_interface, _accessor)
        	if (name != "")
            	return "&" + name
        }
        return "static_cast<" + _method.getErrorDeploymentType(false) + " *>(nullptr)"
    }
    
    ////////////////////
    // Get deployable //
    ////////////////////
    def String getDeployable(FArgument _argument, FInterface _interface, PropertyAccessor _accessor) {
        return "CommonAPI::Deployable<" + _argument.getTypeName(_interface, true) + ", " + _argument.getDeploymentType(_interface, true) + ">"
    }
    
    def String getDeployables(EList<FArgument> _arguments, FInterface _interface, PropertyAccessor _accessor) {
        return _arguments.map[getDeployable(_interface, _accessor)].join(", ")
    }
    
    def String getDeploymentTypes(EList<FArgument> _arguments, FInterface _interface, PropertyAccessor _accessor) {
        return _arguments.map[getDeploymentType(_interface, true)].join(", ")
    }

    def boolean hasDeployedArgument(FBroadcast _broadcast, PropertyAccessor _accessor) {
        for (a : _broadcast.outArgs) {
            if (_accessor.hasDeployment(a)) {
                return true
            }
        }        
        return false
    }

    def String getDeployments(FBroadcast _broadcast, 
                              FInterface _interface, 
                              PropertyAccessor _accessor) {
        return "std::make_tuple(" + _broadcast.outArgs.map[getDeploymentRef(it.array, _broadcast, _interface, _accessor)].join(", ")  + ")"
   }
    
    def boolean hasDeployedArgument(FMethod _method, PropertyAccessor _accessor, 
                                             boolean _in, boolean _out) {
        if (_in) {                                                 
            for (a : _method.inArgs) {
                if (_accessor.hasDeployment(a)) {
                    return true
                }
            }
        }
        
        if (_out) {
            for (a : _method.outArgs) {
                if (_accessor.hasDeployment(a)) {
                    return true
                }
            }
        }
                
        return false
    }

    def String getDeployments(FMethod _method, 
                              FInterface _interface, 
                              PropertyAccessor _accessor,
                              boolean _withInArgs, boolean _withOutArgs) {
        var String inArgsDeployments = ""
        if (_withInArgs) {
            inArgsDeployments = _method.inArgs.map[getDeploymentRef(it.array, _method, _interface, _accessor)].join(", ")
        }
        
        var String outArgsDeployments = ""
        if (_withOutArgs) {
            outArgsDeployments = _method.outArgs.map[getDeploymentRef(it.array, _method, _interface, _accessor)].join(", ")
            if (_method.hasError) {
                var String errorDeployment = _method.getErrorDeploymentRef(_interface, _accessor)
                if (outArgsDeployments != "")
                    outArgsDeployments = errorDeployment + ", " + outArgsDeployments
                else
                    outArgsDeployments = errorDeployment
            }
        }
        
        var String deployments = inArgsDeployments
        if (outArgsDeployments != "") {
            if (deployments != "") deployments += ", "
            deployments += outArgsDeployments
        }
        
        return "std::make_tuple(" + deployments + ")"
    }

    def String getProxyOutArguments(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        val boolean isDeployed = _method.hasDeployedArgument(_accessor, false, true) 
        var String error = ""
        if (_method.hasError) {
            if (isDeployed) {
                error = "_error, "   
            } else {
                error = _method.getErrorNameReference(_method.eContainer) + ", "
            }
        }
        
        if (isDeployed) {
            return "std::make_tuple(" + error + _method.outArgs.map["deploy_" + elementName].join(", ") + ")"
        } else {
            return "std::tuple<" + error + _method.outTypeList + ">()"
        }
    }

    def String generateDeployedStubSignature(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        var String arguments = "const std::shared_ptr<CommonAPI::ClientId> _client"
        for (a : _method.inArgs) {
            arguments += ", const " + a.getDeployable(_interface, _accessor) + " &_" + a.name
        }
        arguments += ", " + _method.elementName + "SomeIpReply_t _reply"
        return arguments
    }
    
    def generateSomeIpStubReturnSignature(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        var signature = ""

        if (_method.hasError)
            signature += _method.getErrorNameReference(_method.eContainer) + ' _error'
        if (_method.hasError && !_method.outArgs.empty)
            signature += ', '

        if (!_method.outArgs.empty)
            signature += _method.outArgs.map[getDeployable(_interface, _accessor) + ' _' + elementName].join(', ')

        return signature
    }

    def generateArgumentsToSomeIpStub(FMethod _method, PropertyAccessor _accessor) {
        var arguments = ' _client'
        
        for (a : _method.inArgs) {
            if (_accessor.hasDeployment(a)) {
                arguments += ", _" + a.name + ".getValue()"
            } else {
                arguments += ", _" + a.name
            }
        }
        
        if (!_method.isFireAndForget)
            arguments = arguments + ', _reply'
        
        return arguments
    }
    
    ///////////////////////////////////////////////////////////
    // Get reference (C++ pointer) to a deployment parameter //
    ///////////////////////////////////////////////////////////
    def String getDeploymentRef(FTypedElement _typedElement, FModelElement _element, PropertyAccessor _accessor) {
        val String name = _typedElement.getDeploymentName(_element, null, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _typedElement.getDeploymentType(null, false) + "*>(nullptr)"
    }

    def String getDeploymentRef(FTypeRef _typeRef, PropertyAccessor _accessor) {
        val String name = _typeRef.getDeploymentName(null, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _typeRef.getDeploymentType(null, false) + "*>(nullptr)"
    }
    
    def String getDeploymentRef(FType _type, PropertyAccessor _accessor) {
        val String name = _type.getDeploymentName(null, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _type.getDeploymentType(null, false) + "*>(nullptr)"
    }
    
    def String getDeploymentRef(FBasicTypeId _typeId, PropertyAccessor _accessor) {
        val String name = _typeId.getDeploymentName(null, _accessor)
        if (name != "")
            return "&" + name
            
        return "static_cast<" + _typeId.getDeploymentType(null, false) + "*>(nullptr)"
    }
    
    // Error deployment
    def String getErrorDeploymentType(FMethod _method, boolean _isArgument) {
        var String deploymentType = ""
        if (_method.hasError) {
            deploymentType = "CommonAPI::SomeIP::EnumerationDeployment"
	        if (_isArgument && !_method.outArgs.empty)
	        	deploymentType = deploymentType + ", "
        }
        return deploymentType
    }

    def Set<String> getDeploymentInputIncludes(FInterface _interface, PropertyAccessor _accessor) {
       var Set<String> ret = new HashSet<String>()
       for(x: _interface.attributes) {
          if(x.type.derived != null) {
             ret.add(someipDeploymentHeaderPath(x.type.derived.eContainer as FTypeCollection))
          }
			if(x.type.derived instanceof FTypeDef) {
				addDeploymentHeaderforTypeDef((x.type.derived as FTypeDef), ret)
			}
       }
       for(x: _interface.broadcasts) {
           for(y: x.outArgs) {
              if(y.type.derived != null) {
                  ret.add(someipDeploymentHeaderPath(y.type.derived.eContainer as FTypeCollection))
              }
			if(y.type.derived instanceof FTypeDef) {
				addDeploymentHeaderforTypeDef((y.type.derived as FTypeDef), ret)
			}
           }
           if(x.hasDeployedArgument(_accessor)) {
           		ret.add(_interface.someipDeploymentHeaderPath)
           }
       }
       for(x: _interface.methods) {
          for(y: x.outArgs) {
             if(y.type.derived != null) {
               ret.add(someipDeploymentHeaderPath(y.type.derived.eContainer as FTypeCollection))
             }
			if(y.type.derived instanceof FTypeDef) {
				addDeploymentHeaderforTypeDef((y.type.derived as FTypeDef), ret)
			}
          }
          for(y: x.inArgs) {
             if(y.type.derived != null) {
               ret.add(someipDeploymentHeaderPath(y.type.derived.eContainer as FTypeCollection))
             }
			if(y.type.derived instanceof FTypeDef) {
				addDeploymentHeaderforTypeDef((y.type.derived as FTypeDef), ret)
			}
          }
          if(x.hasDeployedArgument(_accessor, true, true)) {
           		ret.add(_interface.someipDeploymentHeaderPath)
           } 
       }
       return ret
    }
	
	def addDeploymentHeaderforTypeDef(FTypeDef typedef, Set<String> headers) {

		var derived = typedef.actualType.derived
		if(derived != null && (derived.eContainer as FTypeCollection) != null) {
			headers.add(someipDeploymentHeaderPath((typedef.actualType.derived.eContainer as FTypeCollection)))
		}
	}
	
}
