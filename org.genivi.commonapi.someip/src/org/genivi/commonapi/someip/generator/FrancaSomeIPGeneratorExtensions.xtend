/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.generator

import java.util.ArrayList
import java.util.HashSet
import java.util.List
import java.util.Set
import javax.inject.Inject
import org.eclipse.emf.common.util.EList
import org.franca.core.franca.FArgument
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FArrayType
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
import org.franca.core.franca.FStructType
import org.franca.core.franca.FUnionType
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP
import org.osgi.framework.FrameworkUtil
import org.franca.core.franca.FMapType
import org.franca.core.franca.FIntegerInterval

class FrancaSomeIPGeneratorExtensions {
    @Inject extension FrancaGeneratorExtensions
    @Inject extension FrancaSomeIPDeploymentAccessorHelper

    def PropertyAccessor getSomeIpAccessor(FTypeCollection _tc) {
        val itsAccessor = getAccessor(_tc) as PropertyAccessor
        
        if (itsAccessor === null) {
            var String tcType = null
            if (_tc instanceof FInterface) {
                tcType = "interface "
            } else {
                tcType = "type collection "
            }
            throw new IllegalArgumentException("Could not find a accessor for " + tcType + _tc.name)
        }

        return itsAccessor
    }

    def getSomeIPVersion() {
        val bundle = FrameworkUtil::getBundle(this.getClass())
        val bundleContext = bundle.getBundleContext();
        for (b : bundleContext.bundles) {
            if (b.symbolicName.equals("org.genivi.commonapi.someip")) {
                return b.version
            }
        }
    }

    def generateCommonApiSomeIPLicenseHeader() '''
        /*
         * This file was generated by the CommonAPI Generators.
         * Used org.genivi.commonapi.someip «getSomeIPVersion()».
         * Used org.franca.core «FrancaGeneratorExtensions::getFrancaVersion()».
         *
         «getCommentedString(getSomeIPLicenseHeader())»
         */
    '''

    def getSomeIPLicenseHeader() {
        return FPreferencesSomeIP::instance.getPreference(PreferenceConstantsSomeIP::P_LICENSE_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_LICENSE)
    }

    def String someipDeploymentHeaderFile(FInterface fInterface) {
        return fInterface.elementName + "SomeIPDeployment.hpp"
    }

    def String someipDeploymentHeaderPath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' +
            fInterface.someipDeploymentHeaderFile
    }

    def String someipDeploymentSourceFile(FInterface fInterface) {
        return fInterface.elementName + "SomeIPDeployment.cpp"
    }

    def String someipDeploymentSourcePath(FInterface fInterface) {
        return fInterface.versionPathPrefix + fInterface.model.directoryPath + '/' +
            fInterface.someipDeploymentSourceFile
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

    def String getEventIdentifier(FBroadcast _broadcast, PropertyAccessor _accessor) {
        val Integer value = _accessor.getSomeIpEventID(_broadcast)
        if (value !== null)
            return "CommonAPI::SomeIP::event_id_t(0x" + value.toHexString + ")"
        return "UNDEFINED_EVENT_ID"
    }

    def List<String> getEventGroups(FBroadcast _broadcast, PropertyAccessor _accessor) {
        val List<Integer> value = _accessor.getSomeIpEventGroups(_broadcast)
        if (value !== null)
            return value.map[id|"0x" + id.toHexString]

        var List<String> dummy = new ArrayList<String>
        dummy.add("UNDEFINED_EVENTGROUP_ID");
        return dummy
    }

    def String isReliable(FBroadcast _broadcast, PropertyAccessor _accessor) {
        val Boolean value = _accessor.getSomeIpReliable(_broadcast)
        if (value !== null)
            return value.toString
        return "false"
    }

    def String getReliabilityType(FBroadcast _broadcast, PropertyAccessor _accessor) {
        if (_broadcast.isReliable(_accessor) === "true") {
            return "CommonAPI::SomeIP::reliability_type_e::RT_RELIABLE"
        } else {
            return "CommonAPI::SomeIP::reliability_type_e::RT_UNRELIABLE"
        }
    }

    def String isNotifierReliable(FAttribute _attribute, PropertyAccessor _accessor) {
        val Boolean value = _accessor.getSomeIpNotifierReliable(_attribute)
        if (value !== null)
            return value.toString
        return "false"
    }

    def String getNotifierReliabilityType(FAttribute _attribute, PropertyAccessor _accessor) {
        if (_attribute.isNotifierReliable(_accessor) === "true") {
            return "CommonAPI::SomeIP::reliability_type_e::RT_RELIABLE"
        } else {
            return "CommonAPI::SomeIP::reliability_type_e::RT_UNRELIABLE"
        }
    }

    def String getMethodIdentifier(FMethod _method, PropertyAccessor _accessor) {
        val Integer value = _accessor.getSomeIpMethodID(_method)
        if (value !== null)
            return "CommonAPI::SomeIP::method_id_t(0x" + value.toHexString + ")"
        return "UNDEFINED_METHOD_ID"
    }

    def String isReliable(FMethod _method, PropertyAccessor _accessor) {
        val Boolean value = _accessor.getSomeIpReliable(_method)
        if (value !== null)
            return value.toString
        return "false"
    }

    def String isLittleEndian(FMethod _method, PropertyAccessor _accessor) {
        return _accessor.getSomeIpEndianess(_method)
    }

    def String getDeployment(FBasicTypeId _type) {
        var String itsDeployment = "CommonAPI::SomeIP::IntegerDeployment<"
        itsDeployment += _type.literal.toLowerCase + "_t>"
        return itsDeployment
    }

    def String getGetterIdentifier(FAttribute _attribute, PropertyAccessor _accessor) {
        val Integer value = _accessor.getSomeIpGetterID(_attribute)
        var String getter = "0x0"
        if (value !== null)
            getter = "0x" + value.toHexString

        return "CommonAPI::SomeIP::method_id_t(" + getter + ")"
    }

    def String getSetterIdentifier(FAttribute _attribute, PropertyAccessor _accessor) {
        val Integer value = _accessor.getSomeIpSetterID(_attribute)
        if (value !== null)
            return "CommonAPI::SomeIP::method_id_t(0x" + value.toHexString + ")"
        return "UNDEFINED_SETTER_ID"
    }

    def String getNotifierIdentifier(FAttribute _attribute, PropertyAccessor _accessor) {
        val Integer value = _accessor.getSomeIpNotifierID(_attribute)
        if (value !== null)
            return "CommonAPI::SomeIP::event_id_t(0x" + value.toHexString + ")"
        return "UNDEFINED_NOTIFIER_ID"

    }

    def List<String> getNotifierEventGroups(FAttribute _attribute, PropertyAccessor _accessor) {
        val List<Integer> value = _accessor.getSomeIpEventGroups(_attribute)
        if (value !== null)
            return value.map[id|"CommonAPI::SomeIP::eventgroup_id_t(0x" + id.toHexString + ")"]

        var List<String> dummy = new ArrayList<String>()
        dummy.add("UNDEFINED_EVENTGROUP_ID")
        return dummy
    }

    def String getEndianess(FAttribute _attribute, PropertyAccessor _accessor) {
        return _accessor.getSomeIpEndianess(_attribute)
    }

    def String getEndianess(FBroadcast _broadcast, PropertyAccessor _accessor) {
        return _accessor.getSomeIpEndianess(_broadcast)
    }

    def String getSomeIpServiceID(FInterface _interface) {
        var serviceid = _interface.someIpAccessor.getSomeIpServiceID(_interface)
        if (serviceid !== null) {
            return "0x" + Integer.toHexString(serviceid)
        }
        return "UNDEFINED_SERVICE_ID"
    }

    def String isGetterReliable(FAttribute _attribute, PropertyAccessor _accessor) {
        val Boolean value = _accessor.getSomeIpGetterReliable(_attribute)
        if (value !== null)
            return value.toString
        return "false"
    }

    def String isSetterReliable(FAttribute _attribute, PropertyAccessor _accessor) {
        val Boolean value = _accessor.getSomeIpSetterReliable(_attribute)
        if (value !== null)
            return value.toString
        return "false"
    }

    ////////////////////////////////////////
    // Get deployment type for an element //
    ////////////////////////////////////////
    def dispatch String getDeploymentType(FTypeDef _typeDef, FTypeCollection _interface, boolean _useTc) {
        return _typeDef.actualType.getDeploymentType(_interface, _useTc)
    }

    def dispatch String getDeploymentType(FTypedElement _typedElement, FTypeCollection _interface, boolean _useTc) {
        if (_typedElement.array)
            return "CommonAPI::SomeIP::ArrayDeployment< " + _typedElement.type.getDeploymentType(_interface, _useTc) +
                " >"
        return _typedElement.type.getDeploymentType(_interface, _useTc)
    }

    def dispatch String getDeploymentType(FTypeRef _typeRef, FTypeCollection _interface, boolean _useTc) {
        if (_typeRef.derived !== null)
            return _typeRef.derived.getDeploymentType(_interface, _useTc)
        if (_typeRef.interval !== null)
            return _typeRef.interval.getDeploymentType(_interface, _useTc)
        if (_typeRef.predefined !== null)
            return _typeRef.predefined.getDeploymentType(_interface, _useTc)

        return "CommonAPI::EmptyDeployment"
    }
    def dispatch String getDeploymentType(FIntegerInterval _interval, FTypeCollection _interface, boolean _useTc) {
        return "CommonAPI::SomeIP::IntegerDeployment<int32_t>"
    }
    def dispatch String getDeploymentType(FBasicTypeId _type, FTypeCollection _interface, boolean _useTc) {
        if (_type == FBasicTypeId.STRING)
            return "CommonAPI::SomeIP::StringDeployment"
        else if (_type == FBasicTypeId.BYTE_BUFFER)
            return "CommonAPI::SomeIP::ByteBufferDeployment"
        else if (_type == FBasicTypeId.INT8 || _type == FBasicTypeId.INT16 ||
            _type == FBasicTypeId.INT32 || _type == FBasicTypeId.INT64 ||
            _type == FBasicTypeId.UINT8 || _type == FBasicTypeId.UINT16 ||
            _type == FBasicTypeId.UINT32 || _type == FBasicTypeId.UINT64)
            return _type.deployment
        return "CommonAPI::EmptyDeployment"
    }

    def dispatch String getDeploymentType(FType _type, FTypeCollection _interface, boolean _useTc) {
        var String deploymentType = ""

        if (_useTc) {
            deploymentType = _type.eContainer.getFullName() + "_::"
        }
        deploymentType += _type.name + "Deployment_t"
    }

    ////////////////////////////////////////
    // Get deployment qualified name for an element //
    ////////////////////////////////////////
    def String getDeploymentName(FTypedElement _typedElement, FModelElement _element, FTypeCollection _tc,
        PropertyAccessor _accessor) {
        if (_accessor.hasSpecificDeployment(_typedElement) ||
            _typedElement.array && _accessor.hasDeployment(_typedElement)) {

            var String accessorName = _accessor.name
            // remove rightmost '_' for compatibility's sake
            if (_accessor.name.length > 0)
                accessorName = _accessor.name.substring(0, _accessor.name.length() - 1)

            var String deployment = _tc.fullName + "_::"
            /*
            if (_element !== null) {
                val container = _element.eContainer()
                if (container instanceof FTypeCollection) {
                    deployment += container.getFullName + "_::"
                }
            } else {
                val container = _typedElement.eContainer()
                if (container instanceof FTypeCollection) {
                    deployment += container.getFullName + "_::"
                }
            }
            */
            deployment += accessorName + "Deployment"
            return deployment
        } else {
            return _typedElement.type.getDeploymentName(_tc, _accessor)
        }
    }

    def dispatch String getDeploymentName(FTypeDef _typeDef, FTypeCollection _tc, PropertyAccessor _accessor) {
        return _typeDef.actualType.getDeploymentName(_tc, _accessor)
    }

    def dispatch String getDeploymentName(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_typeRef.derived !== null) {
            return _typeRef.derived.getDeploymentName(_tc, _accessor)
        }
        else if (_typeRef.interval !== null) {
            return _typeRef.interval.getDeploymentName(_tc, _accessor)
        }
        return _typeRef.predefined.getDeploymentName(_tc, _accessor)
    }

    def dispatch String getDeploymentName(FType _type, FTypeCollection _tc, PropertyAccessor _accessor) {
        if (_accessor.hasDeployment(_type) ) {
            // This code caused an issue related to enumerations overwrites
            // if (_accessor.isProperOverwrite()) {
            //     return _tc.getFullName + "_::" + _accessor.getName() +  _type.name + "Deployment"
            // }else {
            val container = _type.eContainer() as FTypeCollection
            return container.getFullName + "_::" + _type.name + "Deployment"
            
        }
        return ""
    }
    def dispatch String getDeploymentName(FIntegerInterval _interval, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }
    def dispatch String getDeploymentName(FBasicTypeId _typeId, FTypeCollection _tc, PropertyAccessor _accessor) {
        return ""
    }

    ///////////////////////////////////////////////////////////
    // Get reference (C++ pointer) to a deployment parameter //
    ///////////////////////////////////////////////////////////
    def String getDeploymentRef(FTypedElement _typedElement, boolean _isArray, FModelElement _element,
        FInterface _interface, PropertyAccessor _accessor) {
        val String name = _typedElement.getDeploymentName(_element, _interface, _accessor)
        if (name != "")
            return "&" + name

        var String deployment = "static_cast< "
        deployment += _typedElement.getDeploymentType(_interface, true)
        deployment += "* >(nullptr)"
        return deployment
    }

    def String getErrorDeploymentRef(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        var String name = ""
        if (_method.errorEnum !== null) {
            name += _method.errorEnum.getDeploymentName(_interface, _accessor)
            if (name != "")
                return "&" + name
        }
        return "static_cast< " + _method.getErrorDeploymentType(false) + " * >(nullptr)"
    }

    ////////////////////
    // Get deployable //
    ////////////////////
    def String getDeployable(FArgument _argument, FInterface _interface, PropertyAccessor _accessor) {
        return "CommonAPI::Deployable< " + _argument.getTypeName(_interface, true) + ", " +
            _argument.getDeploymentType(_interface, true) + " >"
    }

    def String getDeployables(EList<FArgument> _arguments, FInterface _interface, PropertyAccessor _accessor) {
        return _arguments.map[getDeployable(_interface, _accessor)].join(", ")
    }

    def String getDeploymentTypes(EList<FArgument> _arguments, FInterface _interface, PropertyAccessor _accessor) {
        return _arguments.map[getDeploymentType(_interface, true)].join(", ")
    }

    def boolean hasDeployedArgument(FBroadcast _broadcast, PropertyAccessor _accessor) {
        for (a : _broadcast.outArgs) {
            if (_accessor.getOverwriteAccessor(a).hasDeployment(a)) {
                return true
            }
        }
        return false
    }

    def String getDeployments(FBroadcast _broadcast, FInterface _interface,
        PropertyAccessor _accessor) {
        return "std::make_tuple(" +
            _broadcast.outArgs.map[getDeploymentRef(it.array, _broadcast, _interface, _accessor.getOverwriteAccessor(it))].join(", ") + ")"
    }

    def boolean hasDeployedArgument(FMethod _method, PropertyAccessor _accessor,
        boolean _in, boolean _out) {
        if (_in) {
            for (a : _method.inArgs) {
                if (_accessor.getOverwriteAccessor(a).hasDeployment(a)) {
                    return true
                }
            }
        }

        if (_out) {
            for (a : _method.outArgs) {
                if (_accessor.getOverwriteAccessor(a).hasDeployment(a)) {
                    return true
                }
            }
        }

        return false
    }

    def String getDeployments(FMethod _method, FInterface _interface,
        PropertyAccessor _accessor, boolean _withInArgs, boolean _withOutArgs) {
        var String inArgsDeployments = ""
        if (_withInArgs) {
            inArgsDeployments = _method.inArgs.map[getDeploymentRef(it.array, _method, _interface, _accessor.getOverwriteAccessor(it))].join(", ")
        }

        var String outArgsDeployments = ""
        if (_withOutArgs) {
            outArgsDeployments = _method.outArgs.map[getDeploymentRef(it.array, _method, _interface, _accessor.getOverwriteAccessor(it))].
                join(", ")
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
            if(deployments != "") deployments += ", "
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
            arguments += ", const " + a.getDeployable(_interface, _accessor.getOverwriteAccessor(a)) + " &_" + a.name
        }
        arguments += ", " + _method.elementName + "SomeIpReply_t _reply"
        return arguments
    }

    def generateSomeIpStubReturnSignature(FMethod _method, FInterface _interface, PropertyAccessor _accessor) {
        var signature = ""

        if (_method.hasError) {
            signature += _method.getErrorNameReference(_method.eContainer) + ' _error'
            if (!_method.outArgs.empty)
                signature += ', '
        }

        if (!_method.outArgs.empty)
            signature += _method.outArgs.map[getDeployable(_interface, _accessor.getOverwriteAccessor(it)) + ' _' + elementName].join(', ')

        return signature
    }

    def generateArgumentsToSomeIpStub(FMethod _method, PropertyAccessor _accessor) {
        var arguments = ' _client'

        for (a : _method.inArgs) {
            if (_accessor.getOverwriteAccessor(a).hasDeployment(a)) {
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
    def String getDeploymentRef(FTypedElement _typedElement, FModelElement _element, FTypeCollection _tc, PropertyAccessor _accessor) {
        val String name = _typedElement.getDeploymentName(_element, _tc, _accessor)
        if (name != "")
            return "&" + name

        var String elemType = ''

        if (_typedElement.type.derived !== null) {
            var containerName =_typedElement.type.derived.eContainer.fullName
            var typeName =_typedElement.type.derived.name
            elemType = containerName + "_::" + typeName + "Deployment_t"
            if (_typedElement.array)
                elemType = "CommonAPI::SomeIP::ArrayDeployment< " + elemType + " >"
        } else {
            elemType = _typedElement.getDeploymentType(null, false)
        }

        return "static_cast< " + elemType + "* >(nullptr)"
    }

    def String getDeploymentRef(FTypeRef _typeRef, FTypeCollection _tc, PropertyAccessor _accessor) {
        val String name = _typeRef.getDeploymentName(_tc, _accessor)
        if (name != "")
            return "&" + name

        if(_typeRef.derived !== null) {
            if(_typeRef.derived instanceof FEnumerationType) {
                return "static_cast< " + _typeRef.derived.getDeploymentType(null, true) + "* >(nullptr)"
            }
            var containerName =_typeRef.derived.eContainer.fullName
            var typeName =_typeRef.derived.name
            return "static_cast< " + containerName + "_::" + typeName + "Deployment_t* >(nullptr)"
        }

        return "static_cast< " + _typeRef.getDeploymentType(null, false) + "* >(nullptr)"
    }

    def String getDeploymentRef(FType _type, FTypeCollection _tc, PropertyAccessor _accessor) {
        val String name = _type.getDeploymentName(_tc, _accessor)
        if (name != "")
            return "&" + name

        return "static_cast< " + _type.getDeploymentType(_tc, false) + "* >(nullptr)"
    }

    def String getDeploymentRef(FBasicTypeId _typeId, FTypeCollection _tc, PropertyAccessor _accessor) {
        val String name = _typeId.getDeploymentName(_tc, _accessor)
        if (name != "")
            return "&" + name

        return "static_cast< " + _typeId.getDeploymentType(_tc, false) + "* >(nullptr)"
    }

    // Error deployment
    def String getErrorDeploymentType(FMethod _method, boolean _isArgument) {
        var String deploymentType = ""
        if (_method.hasError) {
            if (_method.errorEnum !== null)
                deploymentType = _method.errorEnum.getDeploymentType(_method.containingInterface, true)
            if (_method.errors !== null)
                if (_method.errors.base !== null)
                    deploymentType = _method.errors.base.getDeploymentType(_method.containingInterface, true)
                else
                    deploymentType = "CommonAPI::EmptyDeployment"
            if (_isArgument && !_method.outArgs.empty)
                deploymentType = deploymentType + ", "
        }
        return deploymentType
    }

    def dispatch Set<String> getDeploymentInputIncludes(FArrayType _array, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_array.eContainer as FTypeCollection))
        ret.addAll(_array.elementType.getDeploymentInputIncludes(_accessor))
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FType _type, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_type.eContainer as FTypeCollection))
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FTypeDef _typeDef, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_typeDef.eContainer as FTypeCollection))
        if (_typeDef.actualType !== null)
            ret.addAll(_typeDef.actualType.getDeploymentInputIncludes(_accessor))
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FTypeRef _typeRef, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        if (_typeRef.derived !== null)
            ret.addAll(_typeRef.derived.getDeploymentInputIncludes(_accessor))
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FStructType _struct, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_struct.eContainer as FTypeCollection))
        var FStructType itsStruct = _struct
        while(itsStruct !== null) {
            for (e : itsStruct.elements) {
                var etype = e.type.derived
                if (etype !== null) {
                    ret.addAll(etype.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(e)))
                }
            }
            itsStruct = itsStruct.base
        }
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FUnionType _union, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_union.eContainer as FTypeCollection))
        var FUnionType itsUnion = _union
        while(itsUnion !== null) {
            for (e : itsUnion.elements) {
                var etype = e.type.derived
                if (etype !== null) {
                    ret.addAll(etype.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(e)))
                }
            }
            itsUnion = itsUnion.base
        }
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FMapType _map, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        ret.add(someipDeploymentHeaderPath(_map.eContainer as FTypeCollection))
        ret.addAll(_map.keyType.getDeploymentInputIncludes(_accessor))
        ret.addAll(_map.valueType.getDeploymentInputIncludes(_accessor))
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FTypeCollection _tc, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        for (t : _tc.types) {
            ret.addAll(t.getDeploymentInputIncludes(_accessor))
        }
        return ret
    }

    def dispatch Set<String> getDeploymentInputIncludes(FInterface _interface, PropertyAccessor _accessor) {
        var Set<String> ret = new HashSet<String>()
        for (x : _interface.attributes) {
            if (x.type.derived !== null) {
                ret.addAll(x.type.derived.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(x)))
            }
            if(_accessor.getOverwriteAccessor(x).hasSpecificDeployment(x) || (x.array && _accessor.getOverwriteAccessor(x).hasDeployment(x))) {
                ret.add(_interface.someipDeploymentHeaderPath)
            }
        }
        for (x : _interface.broadcasts) {
            for (y : x.outArgs) {
                if (y.type.derived !== null) {
                    ret.addAll(y.type.derived.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(y)))
                }
            }
            if (x.hasDeployedArgument(_accessor)) {
                ret.add(_interface.someipDeploymentHeaderPath)
            }
        }
        for (x : _interface.methods) {
            for (y : x.outArgs) {
                if (y.type.derived !== null) {
                    ret.addAll(y.type.derived.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(y)))
                }
            }
            for (y : x.inArgs) {
                if (y.type.derived !== null) {
                    ret.addAll(y.type.derived.getDeploymentInputIncludes(_accessor.getOverwriteAccessor(y)))
                }
            }
            if (x.hasError) {
                if (x.errorEnum !== null)
                    ret.addAll(x.errorEnum.getDeploymentInputIncludes(_accessor))
                if (x.errors !== null)
                    if (x.errors.base !== null)
                        ret.addAll(x.errors.base.getDeploymentInputIncludes(_accessor))
            }
            if (x.hasDeployedArgument(_accessor, true, true)) {
                ret.add(_interface.someipDeploymentHeaderPath)
            }
        }
        for (t : _interface.types) {
            ret.addAll(t.getDeploymentInputIncludes(_accessor))
        }

        return ret
    }

}
