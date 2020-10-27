/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
   package org.genivi.commonapi.someip.deployment.validator

import java.math.BigInteger
import java.util.ArrayList
import java.util.Collection
import java.util.HashMap
import java.util.HashSet
import org.eclipse.emf.common.util.Diagnostic
import org.eclipse.emf.common.util.DiagnosticChain
import org.eclipse.emf.common.util.URI
import org.eclipse.emf.ecore.EObject
import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.emf.ecore.resource.ResourceSet
import org.eclipse.xtext.validation.FeatureBasedDiagnostic
import org.franca.core.franca.FArrayType
import org.franca.core.franca.FAttribute
import org.franca.core.franca.FBasicTypeId
import org.franca.core.franca.FCompoundType
import org.franca.core.franca.FConstantDef
import org.franca.core.franca.FEnumerationType
import org.franca.core.franca.FExpression
import org.franca.core.franca.FField
import org.franca.core.franca.FInitializerExpression
import org.franca.core.franca.FIntegerConstant
import org.franca.core.franca.FInterface
import org.franca.core.franca.FMapType
import org.franca.core.franca.FModel
import org.franca.core.franca.FModelElement
import org.franca.core.franca.FQualifiedElementRef
import org.franca.core.franca.FStructType
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeCollection
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypedElement
import org.franca.core.franca.FUnionType
import org.franca.deploymodel.dsl.fDeploy.FDArgument
import org.franca.deploymodel.dsl.fDeploy.FDArray
import org.franca.deploymodel.dsl.fDeploy.FDAttribute
import org.franca.deploymodel.dsl.fDeploy.FDBroadcast
import org.franca.deploymodel.dsl.fDeploy.FDCompound
import org.franca.deploymodel.dsl.fDeploy.FDCompoundOverwrites
import org.franca.deploymodel.dsl.fDeploy.FDElement
import org.franca.deploymodel.dsl.fDeploy.FDEnumeration
import org.franca.deploymodel.dsl.fDeploy.FDEnumerationOverwrites
import org.franca.deploymodel.dsl.fDeploy.FDEnumerator
import org.franca.deploymodel.dsl.fDeploy.FDExtensionElement
import org.franca.deploymodel.dsl.fDeploy.FDField
import org.franca.deploymodel.dsl.fDeploy.FDGeneric
import org.franca.deploymodel.dsl.fDeploy.FDInteger
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDMethod
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDOverwriteElement
import org.franca.deploymodel.dsl.fDeploy.FDProperty
import org.franca.deploymodel.dsl.fDeploy.FDPropertySet
import org.franca.deploymodel.dsl.fDeploy.FDStruct
import org.franca.deploymodel.dsl.fDeploy.FDTypeDefinition
import org.franca.deploymodel.dsl.fDeploy.FDTypeOverwrites
import org.franca.deploymodel.dsl.fDeploy.FDTypes
import org.franca.deploymodel.dsl.fDeploy.FDUnion
import org.franca.deploymodel.dsl.fDeploy.FDValue
import org.franca.deploymodel.dsl.fDeploy.impl.FDSpecificationImpl
import org.franca.deploymodel.ext.providers.ProviderUtils

import static org.franca.deploymodel.dsl.fDeploy.FDeployPackage.Literals.*

class SomeIPDeploymentValidator
{
	val FIDL_FILE_EXTENSION_SUFFIX = ".fidl"
	val FDEPL_FILE_EXTENSION_SUFFIX = ".fdepl"
	val DEPLOYMENT_SPECIFICATION_FILE_SUFFIX = "_deployment_spec.fdepl"
	val SOMEIP_SPECIFICATION_TYPE = "someip.deployment"
	val CORE_SPECIFICATION_TYPE = "core.deployment"

    val MIN_METHOD_ID_VALUE = 1
    val MAX_METHOD_ID_VALUE = 32767
    val MIN_EVENT_ID_VALUE = 32769
    val MAX_EVENT_ID_VALUE = 65534
    val MIN_EVENT_GROUP_VALUE = 1
    val MAX_EVENT_GROUP_VALUE = 65534

    val DEFAULT_SOMEIP_ENUM_WIDTH = 1

    var DiagnosticChain diagnostics
    var allMethodIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDProperty>>>
    var allEventIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDProperty>>>
    var allEventGroupIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDValue>>>
    var allSelectiveBroadcastEventGroupIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDValue>>>
    var methodIdDiagnostics = new HashSet<FDProperty>
    var eventIdDiagnostics = new HashSet<FDProperty>
    var missingInterfaceDeployment = new HashSet<FInterface>
    var fdInterfaces = new ArrayList<FDInterface>
    var fdInterfaceInstances = new ArrayList<FDExtensionElement>
    var fdTypeCollections = new ArrayList<FDTypes>
    var allFDepls = new ArrayList<FDModel> // all FDModels but without "_deployment_spec.fdepl" files
    var maxEnumValues = new HashMap<FEnumerationType, BigInteger>

    def validate(Collection<FDModel> fdepls, DiagnosticChain diagnostics)
    {
        this.diagnostics = diagnostics

        for (fdepl : fdepls)
        {
            var deplFileName = fdepl.eResource.URI.lastSegment
            if (!deplFileName.endsWith(DEPLOYMENT_SPECIFICATION_FILE_SUFFIX))
            {
                allFDepls.add(fdepl)
                for (fdInterface : fdepl.deployments.filter(typeof(FDInterface)))
                {
                    if (fdInterface.spec.name !== null && fdInterface.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdInterfaces.add(fdInterface)
                }
                for (fdProvider : ProviderUtils.getProviders(fdepl))
                {
                    if (fdProvider.spec.name !== null && fdProvider.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdInterfaceInstances.addAll(ProviderUtils.getInstances(fdProvider))
                }
                for (fdTypes : fdepl.deployments.filter(typeof(FDTypes)))
                {
                    if (fdTypes.spec.name !== null && fdTypes.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdTypeCollections.addAll(fdTypes)
                }
            }
        }

        fdInterfaces.forEach[validateInterface]
        fdInterfaces.forEach[validateIds]
        fdInterfaces.forEach[validateCompleteInterfaceDeployments]

        validateProviderInstanceDeployments
        validateArrayDeployments
        validateMapDeployments
        validateByteBufferDeployments
        validateStringDeployments
        validateUnionDeployments
        validateDeploymentProperties
        validateEnumInvalidValueDeployments
        validateCorePropertyDeployments
        validateImports
        validateEnumBitDeployments
        validateEnumSizeDeployments
    }

    private def validateEnumSizeDeployments()
    {
        fdTypeCollections.forEach[types.forEach[validateEnumSize(it)]]
        fdInterfaces.forEach[
            types.forEach[validateEnumSize(it)]
            attributes.forEach[validateEnumSize(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.forEach[validateEnumSize(it)]
                if (outArguments !== null)
                    outArguments.arguments.forEach[validateEnumSize(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.forEach[validateEnumSize(it)]
            ]
        ]
        validateCompoundMemberEnumSize
    }

    private def validateCompoundMemberEnumSize()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldEnumSize(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldEnumSize(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldEnumSize(it)]
        ]
    }

    private def void validateFieldEnumSize(FDField field)
    {
        if (isEnum(field.target))
            validateEnumSize(field)

        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldEnumSize(it)
            ]
        }
    }

    private def validateEnumSize(FDElement fdElem)
    {
        val enumType = getTargetEnumType(fdElem)
        if (enumType !== null)
            validateEnumSize(fdElem, enumType)
    }

    private def validateEnumSize(FDElement fdElem, FEnumerationType enumType)
    {
        var properties =
            if (fdElem instanceof FDOverwriteElement)
                fdElem.overwrites?.properties
            else
                fdElem.properties

        var FDProperty propSomeIpEnumWidth
        if (properties !== null)
            propSomeIpEnumWidth = properties.items.findFirst[decl.name == "SomeIpEnumWidth"]
        if (propSomeIpEnumWidth === null)
        {
            val fdEnum = getEnumTypeDeployments(enumType)
            if (fdEnum?.properties !== null)
                propSomeIpEnumWidth = fdEnum.properties.items.findFirst[decl.name == "SomeIpEnumWidth"]
        }

        var enumWidth =
            if (propSomeIpEnumWidth !== null)
                (propSomeIpEnumWidth.value.single as FDInteger).value
            else
                DEFAULT_SOMEIP_ENUM_WIDTH

        val maxPossibleEnumValue = getMaxValue(enumWidth)
        val maxUsedEnumValue = getGreatestEnumValue(enumType)
        if (maxUsedEnumValue > maxPossibleEnumValue)
        {
            if (propSomeIpEnumWidth !== null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Deployment size (" + enumWidth + ") of enumeration type \"" + enumType.name + "\" too small to hold max. enumerator value of: " + maxUsedEnumValue,
                    propSomeIpEnumWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
            else
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Enumeration type \"" + enumType.name + "\" needs a deployment with a size greater than the default deployment size of " + DEFAULT_SOMEIP_ENUM_WIDTH + " byte.",
                    fdElem, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    private def getGreatestEnumValue(FEnumerationType enumType)
    {
        var maxValue = maxEnumValues.get(enumType)
        if (maxValue === null)
        {
            maxValue = BigInteger.ZERO
            var curValue = BigInteger.ZERO
            for (enumerator : enumType.enumerators)
            {
                if (enumerator.value !== null)
                {
                    val enumValue = getEnumeratorValue(enumerator.value)
                    // Set 'curValue', only if there is a valid value for the enumerator specified
                    if (enumValue !== null)
                        curValue = enumValue
                }

                if (curValue > maxValue)
                    maxValue = curValue
                curValue += BigInteger.ONE
            }
            maxEnumValues.put(enumType, maxValue)
        }
        return maxValue
    }

    /**
     * See also: org.genivi.commonapi.core.generator.FrancaGeneratorExtensions.getEnumeratorValue
     */
    private def BigInteger getEnumeratorValue(FExpression expression)
    {
        return switch (expression)
        {
            FIntegerConstant: expression.^val
            //FStringConstant: expression.^val
            FQualifiedElementRef: expression.element.constantValue
            default: null
        }
    }

    /**
     * See also: org.genivi.commonapi.core.generator.FrancaGeneratorExtensions.getConstantValue
     */
    private def BigInteger getConstantValue(FModelElement  expression)
    {
        return switch (expression)
        {
            FConstantDef: expression.rhs.constantType
            default: null
        }
    }

    /**
     * See also: org.genivi.commonapi.core.generator.FrancaGeneratorExtensions.getConstantType
     */
    private def BigInteger getConstantType(FInitializerExpression  expression)
    {
        return switch (expression)
        {
            FIntegerConstant: expression.^val
            default: null
        }
    }

    private def validateEnumBitDeployments()
    {
        // This validation is only relevant for 'attributes'
        //
        fdInterfaces.forEach[
            attributes.forEach[
                // If the attribute is set to 'Little Endian', verify if all directly and indirectly
                // referenced 'enum' types do have a bit deployment specified. We cannot traverse the
                // deployment tree here, because we are searching for missing deployment properties,
                // not for existing ones. So, we need to traverse the Franca type and lookup a possible
                // existing deployment for each found enum type.
                //
                val prop = properties.items.findFirst[decl.name == "SomeIpAttributeEndianess"]
                if (prop !== null)
                {
                    val propVal = prop.enumeratorValue
                    if (propVal !== null && propVal == "le")
                        validateEnumBitDeployment(it, it.target?.type, it.overwrites)
                }
            ]
        ]
    }

    private def void validateEnumBitDeployment(FDAttribute fdAttr, FTypeRef typeRef, FDTypeOverwrites overwrites)
    {
        val enumType = getEnum(typeRef)
        if (enumType !== null)
        {
            var FDProperty propSomeIpEnumBitWidth = null

            if (fdAttr.overwrites !== null)
            {
                val properties = getEnumOverwrites(fdAttr.overwrites, typeRef)
                if (properties !== null)
                    propSomeIpEnumBitWidth = properties.items.findFirst[decl.name == "SomeIpEnumBitWidth"]
            }

            if (propSomeIpEnumBitWidth === null && overwrites !== null)
            {
                val properties = getEnumOverwrites(overwrites, typeRef)
                if (properties !== null)
                    propSomeIpEnumBitWidth = properties.items.findFirst[decl.name == "SomeIpEnumBitWidth"]
            }

            if (propSomeIpEnumBitWidth === null)
            {
                val fdEnum = getEnumTypeDeployments(typeRef)
                if (fdEnum?.properties !== null)
                    propSomeIpEnumBitWidth = fdEnum.properties.items.findFirst[decl.name == "SomeIpEnumBitWidth"]
            }

            if (propSomeIpEnumBitWidth === null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Missing bit deployment: Attribute \"" + getAttributeName(fdAttr) + "\" is declared as Little Endian, but the enumeration \"" + getFullTypeName(typeRef) + "\" used does not specify \"SomeIpEnumBitWidth\".",
                    fdAttr, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        else
        {
            val compoundType = getCompound(typeRef)
            if (compoundType !== null)
            {
                val typeDeployments = getCompoundTypeDeployments(typeRef)
                compoundType.elements.forEach[element|
                    var elementOverwrites = overwrites
                    if (typeDeployments !== null)
                    {
                        val elementField = typeDeployments.fields.findFirst[target == element]
                        if (elementField !== null)
                            elementOverwrites = elementField.overwrites
                    }
                    validateEnumBitDeployment(fdAttr, element.type, elementOverwrites)
                ]
            }
        }
    }

    private def FDPropertySet getEnumOverwrites(FDTypeOverwrites fdOverwrites, FTypeRef typeRef)
    {
        if (fdOverwrites instanceof FDCompoundOverwrites)
        {
            for (field : fdOverwrites.fields)
            {
                val properties = getEnumOverwrites(field.overwrites, typeRef)
                if (properties !== null)
                    return properties
            }
        }
        else if (fdOverwrites instanceof FDEnumerationOverwrites)
        {
            if (fdOverwrites.eContainer instanceof FDAttribute)
            {
                if ((fdOverwrites.eContainer as FDAttribute).target.type === typeRef)
                    return fdOverwrites.properties
            }
            else if (fdOverwrites.eContainer instanceof FDField)
            {
                if ((fdOverwrites.eContainer as FDField).target.type === typeRef)
                    return fdOverwrites.properties
            }
        }
        return null
    }

    private def getEnumTypeDeployments(FTypeRef typeRef)
    {
        val enumType = getEnum(typeRef)
        if (enumType !== null)
        {
            val typeContainer = typeRef.eContainer
            if (typeContainer instanceof FAttribute || typeContainer instanceof FField)
            {
                for (fdType : fdTypeCollections)
                {
                    val fd = fdType.types.filter(typeof(FDEnumeration)).findFirst[
                        getEnum(it.target) == enumType
                    ]
                    if (fd !== null)
                        return fd
                }
            }
        }
    }

    private def getEnumTypeDeployments(FEnumerationType enumType)
    {
        for (fdType : fdTypeCollections)
        {
            val fd = fdType.types.filter(typeof(FDEnumeration)).findFirst[
                getEnum(it.target) == enumType
            ]
            if (fd !== null)
                return fd
        }
    }

    private def getCompoundTypeDeployments(FTypeRef typeRef)
    {
        val compoundType = getCompound(typeRef)
        if (compoundType !== null)
        {
            val typeContainer = typeRef.eContainer
            if (typeContainer instanceof FAttribute || typeContainer instanceof FField)
            {
                if (compoundType instanceof FStructType)
                {
                    for (fdType : fdTypeCollections)
                    {
                        val fd = fdType.types.filter(typeof(FDStruct)).findFirst[
                            getCompound(it.target) == compoundType
                        ]
                        if (fd !== null)
                            return fd
                    }
                }
                else if (compoundType instanceof FUnionType)
                {
                    for (fdType : fdTypeCollections)
                    {
                        val fd = fdType.types.filter(typeof(FDUnion)).findFirst[
                            getCompound(it.target) == compoundType
                        ]
                        if (fd !== null)
                            return fd
                    }
                }
            }
        }
    }

    private def validateEnumInvalidValueDeployments()
    {
        fdTypeCollections.forEach[types.forEach[validateEnumInvalidValue(it)]]
        fdInterfaces.forEach[
            types.forEach[validateEnumInvalidValue(it)]
            attributes.forEach[validateEnumInvalidValue(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.forEach[validateEnumInvalidValue(it)]
                if (outArguments !== null)
                    outArguments.arguments.forEach[validateEnumInvalidValue(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.forEach[validateEnumInvalidValue(it)]
            ]
        ]
        validateCompoundMemberEnumInvalidValue
    }

    private def validateCompoundMemberEnumInvalidValue()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldEnumInvalidValue(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldEnumInvalidValue(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldEnumInvalidValue(it)]
        ]
    }

    private def void validateFieldEnumInvalidValue(FDField field)
    {
        if (isEnum(field.target))
            validateEnumInvalidValue(field)

        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldEnumInvalidValue(it)
            ]
        }
    }

    private def validateEnumInvalidValue(FDElement fdElem)
    {
        if (fdElem instanceof FDOverwriteElement)
        {
            if (fdElem.overwrites !== null)
                validateEnumInvalidValue(fdElem.overwrites.properties)
        }
        else
            validateEnumInvalidValue(fdElem.properties)
    }

    private def validateEnumInvalidValue(FDPropertySet properties)
    {
        if (properties !== null)
        {
            val propSomeIpEnumInvalidValue = properties.items.findFirst[decl.name == "SomeIpEnumInvalidValue"]
            if (propSomeIpEnumInvalidValue !== null)
            {
                val enumInvalidValue = BigInteger.valueOf((propSomeIpEnumInvalidValue.value.single as FDInteger).value)

                var enumWidth = DEFAULT_SOMEIP_ENUM_WIDTH
                val propSomeIpEnumWidth = properties.items.findFirst[decl.name == "SomeIpEnumWidth"]
                if (propSomeIpEnumWidth !== null)
                    enumWidth = (propSomeIpEnumWidth.value.single as FDInteger).value

                val maxEnumValue = getMaxValue(enumWidth)
                if (enumInvalidValue > maxEnumValue)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Value of \"SomeIpEnumInvalidValue\" does not fit into an integer with a size of \"SomeIpEnumWidth = " + enumWidth + "\".",
                        propSomeIpEnumInvalidValue, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
        }
    }

    val BigInteger1  = new BigInteger("ff", 16)
    val BigInteger2  = new BigInteger("ffFF", 16)
    val BigInteger3  = new BigInteger("ffFFff", 16)
    val BigInteger4  = new BigInteger("ffFFffFF", 16)
    val BigInteger5  = new BigInteger("ffFFffFFff", 16)
    val BigInteger6  = new BigInteger("ffFFffFFffFF", 16)
    val BigInteger7  = new BigInteger("ffFFffFFffFFff", 16)
    val BigInteger8  = new BigInteger("ffFFffFFffFFffFF", 16)

    private def getMaxValue(int bytes)
    {
        if (bytes == 0)     return BigInteger.ZERO
        if (bytes == 1)     return BigInteger1
        if (bytes == 2)     return BigInteger2
        if (bytes == 3)     return BigInteger3
        if (bytes == 4)     return BigInteger4
        if (bytes == 5)     return BigInteger5
        if (bytes == 6)     return BigInteger6
        if (bytes == 7)     return BigInteger7
        /*if (bytes == 8)*/ return BigInteger8
    }

    ///////////////////////////////////////////////////////////////////////////
    // Enum
    ///////////////////////////////////////////////////////////////////////////

    private def boolean isEnum(FTypedElement elm)
    {
        if (elm !== null)
            return isEnum(elm.type)
        return false
    }

    private def boolean isEnum(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isEnum(typeRef.derived)
        }
        return false
    }

    private def boolean isEnum(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isEnum(typ.actualType)
        }
        else if (typ instanceof FEnumerationType)
        {
            return true
        }
        return false
    }

    private def FEnumerationType getEnum(FTypedElement elm)
    {
        if (elm !== null)
            return getEnum(elm.type)
        return null
    }

    private def FEnumerationType getEnum(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return getEnum(typeRef.derived)
        }
        return null
    }

    private def FEnumerationType getEnum(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return getEnum(typ.actualType)
        }
        else if (typ instanceof FEnumerationType)
        {
            return typ
        }
        return null
    }

    ///////////////////////////////////////////////////////////////////////////
    // Array
    ///////////////////////////////////////////////////////////////////////////

    private def validateArrayDeployments()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDArray)).forEach[validateArrayDeployment(it)]]
        fdInterfaces.forEach[
            types.filter(typeof(FDArray)).forEach[validateArrayDeployment(it)]
            attributes.filter[isArray(target)].forEach[validateArrayDeployment(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.filter[isArray(target)].forEach[validateArrayDeployment(it)]
                if (outArguments !== null)
                    outArguments.arguments.filter[isArray(target)].forEach[validateArrayDeployment(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.filter[isArray(target)].forEach[validateArrayDeployment(it)]
            ]
        ]
        validateCompoundMemberArrayDeployments
    }

    private def validateCompoundMemberArrayDeployments()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldArrayDeployments(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldArrayDeployments(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldArrayDeployments(it)]
        ]
    }

    private def void validateFieldArrayDeployments(FDField field)
    {
        if (isArray(field.target)) {
            validateArrayDeployment(field)
        }
        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldArrayDeployments(it)
            ]
        }
    }

    private def validateArrayDeployment(FDElement fdArray)
    {
        val String minLengthName = "SomeIpArrayMinLength"
        val String maxLengthName = "SomeIpArrayMaxLength"
        val String lengthWidthName = "SomeIpArrayLengthWidth"

        val FDPropertySet properties =
            if (fdArray instanceof FDOverwriteElement && (fdArray as FDOverwriteElement).overwrites !== null)
                (fdArray as FDOverwriteElement).overwrites.properties
            else
                fdArray.properties

        val propSomeIpArrayMinLength = properties.items.findFirst[it.decl.name == minLengthName]
        val propSomeIpArrayMaxLength = properties.items.findFirst[it.decl.name == maxLengthName]
        val propSomeIpArrayLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        var someIpArrayMinLength = getInteger(propSomeIpArrayMinLength)
        var someIpArrayMaxLength = getInteger(propSomeIpArrayMaxLength)
        var someIpArrayLengthWidth = getInteger(propSomeIpArrayLengthWidth)

        if (someIpArrayMinLength !== null && someIpArrayMaxLength !== null && someIpArrayMinLength == someIpArrayMaxLength && someIpArrayMinLength != 0)
        {
            // * If SomeIpArrayLengthWidth == 1, 2 or 4 bytes, SomeIpArrayMinLength and SomeIpArrayMaxLength are ignored.
            //
            if (someIpArrayLengthWidth === null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment with '" + minLengthName + " = " + someIpArrayMinLength + "'; '"+ maxLengthName + " = " + someIpArrayMaxLength + "' is missing a '" + lengthWidthName + " = 0' property.",
                    propSomeIpArrayMinLength, null, -1, null, null)
                diagnostics.add(diag)
            }
            else if (someIpArrayLengthWidth != 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment with '" + minLengthName + " = " + someIpArrayMinLength + "'; '"+ maxLengthName + " = " + someIpArrayMaxLength + "' does not specify '" + lengthWidthName + " = 0'.",
                    propSomeIpArrayLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        else if (someIpArrayLengthWidth !== null && someIpArrayLengthWidth == 0)
        {
            // * If SomeIpArrayLengthWidth == 0, the array has SomeIpArrayMaxLength elements.
            //
            if (someIpArrayMaxLength === null || someIpArrayMaxLength == 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment specifies a fixed length array type, but is missing a nonzero array length specification '" + maxLengthName + "'.",
                    propSomeIpArrayLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        if ((someIpArrayLengthWidth === null || someIpArrayLengthWidth == 0) && someIpArrayMinLength !== null && someIpArrayMaxLength !== null && someIpArrayMinLength > someIpArrayMaxLength)
        {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "Array deployment contains a minimum array length '" + minLengthName + "' that exceeds the maximum array length '" + maxLengthName + "'.",
                propSomeIpArrayMinLength, null, -1, null, null)
            diagnostics.add(diag)
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Map
    ///////////////////////////////////////////////////////////////////////////

    private def validateMapDeployments()
    {
        fdInterfaces.forEach[
            attributes.forEach[
                if (isMap(target))
                    validateMapDeployment(it, "SomeIpAttrMapMinLength", "SomeIpAttrMapMaxLength", "SomeIpAttrMapLengthWidth")
                else
                    warnAboutMapDeployment(it, "SomeIpAttrMapMinLength", "SomeIpAttrMapMaxLength", "SomeIpAttrMapLengthWidth")
            ]

            val fdArguments = new ArrayList<FDArgument>
            methods.forEach[
                if (inArguments !== null)
                    fdArguments.addAll(inArguments.arguments)
                if (outArguments !== null)
                    fdArguments.addAll(outArguments.arguments)
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    fdArguments.addAll(outArguments.arguments)
            ]
            fdArguments.forEach[
                if (isMap(target))
                    validateMapDeployment(it, "SomeIpArgMapMinLength", "SomeIpArgMapMaxLength", "SomeIpArgMapLengthWidth")
                else
                    warnAboutMapDeployment(it, "SomeIpArgMapMinLength", "SomeIpArgMapMaxLength", "SomeIpArgMapLengthWidth")
            ]
        ]
    }

    private def validateMapDeployment(FDElement fd, String minLengthName, String maxLengthName, String lengthWidthName)
    {
        val FDPropertySet properties =
            if (fd instanceof FDOverwriteElement && (fd as FDOverwriteElement).overwrites !== null)
                (fd as FDOverwriteElement).overwrites.properties
            else
                fd.properties

        val propSomeIpMapMinLength = properties.items.findFirst[it.decl.name == minLengthName]
        val propSomeIpMapMaxLength = properties.items.findFirst[it.decl.name == maxLengthName]
        val propSomeIpMapLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        var someIpMapMinLength = getInteger(propSomeIpMapMinLength)
        var someIpMapMaxLength = getInteger(propSomeIpMapMaxLength)
        var someIpMapLengthWidth = getInteger(propSomeIpMapLengthWidth)

        if (someIpMapMinLength !== null && someIpMapMaxLength !== null && someIpMapMinLength == someIpMapMaxLength && someIpMapMinLength != 0)
        {
            // * If SomeIpMapLengthWidth == 1, 2 or 4 bytes, SomeIpMapMinLength and SomeIpMapMaxLength are ignored.
            //
            if (someIpMapLengthWidth === null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Map deployment with '" + minLengthName + " = " + someIpMapMinLength + "'; '"+ maxLengthName + " = " + someIpMapMaxLength + "' is missing a '" + lengthWidthName + " = 0' property.",
                    propSomeIpMapMinLength, null, -1, null, null)
                diagnostics.add(diag)
            }
            else if (someIpMapLengthWidth != 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Map deployment with '" + minLengthName + " = " + someIpMapMinLength + "'; '"+ maxLengthName + " = " + someIpMapMaxLength + "' does not specify '" + lengthWidthName + " = 0'.",
                    propSomeIpMapLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        else if (someIpMapLengthWidth !== null && someIpMapLengthWidth == 0)
        {
            // * If SomeIpMapLengthWidth == 0, the map has SomeIpMapMaxLength elements.
            //
            if (someIpMapMaxLength === null || someIpMapMaxLength == 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Map deployment specifies a fixed length map type, but is missing a nonzero map length specification '" + maxLengthName + "'.",
                    propSomeIpMapLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        if ((someIpMapLengthWidth === null || someIpMapLengthWidth == 0) && someIpMapMinLength !== null && someIpMapMaxLength !== null && someIpMapMinLength > someIpMapMaxLength)
        {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "Map deployment contains a minimum map length '" + minLengthName + "' that exceeds the maximum map length '" + maxLengthName + "'.",
                propSomeIpMapMinLength, null, -1, null, null)
            diagnostics.add(diag)
        }
    }

    private def warnAboutMapDeployment(FDElement fd, String minLengthName, String maxLengthName, String lengthWidthName)
    {
        val FDPropertySet properties =
            if (fd instanceof FDOverwriteElement && (fd as FDOverwriteElement).overwrites !== null)
                (fd as FDOverwriteElement).overwrites.properties
            else
                fd.properties

        val propSomeIpMapMinLength = properties.items.findFirst[it.decl.name == minLengthName]
        val propSomeIpMapMaxLength = properties.items.findFirst[it.decl.name == maxLengthName]
        val propSomeIpMapLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        if (propSomeIpMapMinLength !== null) {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "Map deployment used for none map type.",
                propSomeIpMapMinLength, null, -1, null, null)
            diagnostics.add(diag)
        }
        if (propSomeIpMapMaxLength !== null) {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "Map deployment used for none map type.",
                    propSomeIpMapMaxLength, null, -1, null, null)
            diagnostics.add(diag)
        }
        if (propSomeIpMapLengthWidth !== null) {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "Map deployment used for none map type.",
                    propSomeIpMapLengthWidth, null, -1, null, null)
            diagnostics.add(diag)
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // ByteBuffer
    ///////////////////////////////////////////////////////////////////////////

    private def validateByteBufferDeployments()
    {
        fdInterfaces.forEach[
            attributes.filter[isByteBuffer(it.target)].forEach[validateByteBufferDeployment(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.filter[isByteBuffer(target)].forEach[validateByteBufferDeployment(it)]
                if (outArguments !== null)
                    outArguments.arguments.filter[isByteBuffer(target)].forEach[validateByteBufferDeployment(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.filter[isByteBuffer(target)].forEach[validateByteBufferDeployment(it)]
            ]
        ]
        validateCompoundMemberByteBufferDeployments
    }

    private def validateCompoundMemberByteBufferDeployments()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldByteBufferDeployments(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldByteBufferDeployments(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldByteBufferDeployments(it)]
        ]
    }

    private def void validateFieldByteBufferDeployments(FDField field)
    {
        if (isByteBuffer(field.target)) {
            validateByteBufferDeployment(field)
        }
        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldByteBufferDeployments(it)
            ]
        }
    }

    private def validateByteBufferDeployment(FDElement fdByteBuffer)
    {
        val String minLengthName = "SomeIpByteBufferMinLength"
        val String maxLengthName = "SomeIpByteBufferMaxLength"
        val String lengthWidthName = "SomeIpByteBufferLengthWidth"

        val FDPropertySet properties =
            if (fdByteBuffer instanceof FDOverwriteElement && (fdByteBuffer as FDOverwriteElement).overwrites !== null)
                (fdByteBuffer as FDOverwriteElement).overwrites.properties
            else
                fdByteBuffer.properties

        val propSomeIpMinLength = properties.items.findFirst[it.decl.name == minLengthName]
        val propSomeIpMaxLength = properties.items.findFirst[it.decl.name == maxLengthName]
        val propSomeIpLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        var someIpMinLength = getInteger(propSomeIpMinLength)
        var someIpMaxLength = getInteger(propSomeIpMaxLength)
        var someIpLengthWidth = getInteger(propSomeIpLengthWidth)

        if (someIpMinLength !== null && someIpMaxLength !== null && someIpMinLength == someIpMaxLength && someIpMinLength != 0)
        {
            // * If SomeIpByteBufferLengthWidth == 1, 2 or 4 bytes, SomeIpByteBufferMinLength and SomeIpByteBufferMaxLength are ignored.
            //
            if (someIpLengthWidth === null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "ByteBuffer deployment with '" + minLengthName + " = " + someIpMinLength + "'; '"+ maxLengthName + " = " + someIpMaxLength + "' is missing a '" + lengthWidthName + " = 0' property.",
                    propSomeIpMinLength, null, -1, null, null)
                diagnostics.add(diag)
            }
            else if (someIpLengthWidth != 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "ByteBuffer deployment with '" + minLengthName + " = " + someIpMinLength + "'; '"+ maxLengthName + " = " + someIpMaxLength + "' does not specify '" + lengthWidthName + " = 0'.",
                    propSomeIpLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        else if (someIpLengthWidth !== null && someIpLengthWidth == 0)
        {
            // * If SomeIpByteBufferLengthWidth == 0, the array has SomeIpByteBufferMaxLength elements.
            //
            if (someIpMaxLength === null || someIpMaxLength == 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "ByteBuffer deployment specifies a fixed length buffer type, but is missing a nonzero buffer length specification '" + maxLengthName + "'.",
                    propSomeIpLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        if ((someIpLengthWidth === null || someIpLengthWidth == 0) && someIpMinLength !== null && someIpMaxLength !== null && someIpMinLength > someIpMaxLength)
        {
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "ByteBuffer deployment contains a minimum length '" + minLengthName + "' that exceeds the maximum length '" + maxLengthName + "'.",
                propSomeIpMinLength, null, -1, null, null)
            diagnostics.add(diag)
        }
    }


    ///////////////////////////////////////////////////////////////////////////
    // String
    ///////////////////////////////////////////////////////////////////////////

    private def validateStringDeployments()
    {
        fdInterfaces.forEach[
            attributes.filter[isString(target)].forEach[validateStringDeployment(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.filter[isString(target)].forEach[validateStringDeployment(it)]
                if (outArguments !== null)
                    outArguments.arguments.filter[isString(target)].forEach[validateStringDeployment(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.filter[isString(it.target)].forEach[validateStringDeployment(it)]
            ]
        ]
        validateCompoundMemberStringDeployments
    }

    private def validateCompoundMemberStringDeployments()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldStringDeployments(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldStringDeployments(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldStringDeployments(it)]
        ]
    }

    private def void validateFieldStringDeployments(FDField field)
    {
        if (isString(field.target)) {
            validateStringDeployment(field)
        }
        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldStringDeployments(it)
            ]
        }
    }

    private def validateStringDeployment(FDElement fdString)
    {
        val String lengthName = "SomeIpStringLength"
        val String lengthWidthName = "SomeIpStringLengthWidth"

        val FDPropertySet properties =
            if (fdString instanceof FDOverwriteElement && (fdString as FDOverwriteElement).overwrites !== null)
                (fdString as FDOverwriteElement).overwrites.properties
            else
                fdString.properties

        val propSomeIpLength = properties.items.findFirst[it.decl.name == lengthName]
        val propSomeIpLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        var someIpLength = getInteger(propSomeIpLength)
        var someIpLengthWidth = getInteger(propSomeIpLengthWidth)

        if (someIpLengthWidth !== null && someIpLengthWidth == 0)
        {
            // if lengthwidth = 0 the stringlength must be set >= 0
            //
            if (someIpLength === null || someIpLength < 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                    "String deployment specifies 'SomeIpStringLengthWidth = 0', but has no 'SomeIpStringLength >= 0' specified.",
                    propSomeIpLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Union
    ///////////////////////////////////////////////////////////////////////////

    private def validateUnionDeployments()
    {
        fdInterfaces.forEach[
            attributes.filter[isUnion(it.target)].forEach[validateUnionDeployment(it)]
            methods.forEach[
                if (inArguments !== null)
                    inArguments.arguments.filter[isUnion(it.target)].forEach[validateUnionDeployment(it)]
                if (outArguments !== null)
                    outArguments.arguments.filter[isUnion(it.target)].forEach[validateUnionDeployment(it)]
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    outArguments.arguments.filter[isUnion(it.target)].forEach[validateUnionDeployment(it)]
            ]
        ]
        validateCompoundMemberUnionDeployments
    }

    private def validateCompoundMemberUnionDeployments()
    {
        fdTypeCollections.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldUnionDeployments(it)]]]
        fdInterfaces.forEach[types.filter(typeof(FDCompound)).forEach[fields.forEach[validateFieldUnionDeployments(it)]]]

        val overwriteElements = new ArrayList<FDOverwriteElement>
        fdInterfaces.forEach[
            overwriteElements.addAll(attributes.filter[isCompound(target)])
            methods.forEach[
                if (inArguments !== null)
                    overwriteElements.addAll(inArguments.arguments.filter[isCompound(target)])
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
            broadcasts.forEach[
                if (outArguments !== null)
                    overwriteElements.addAll(outArguments.arguments.filter[isCompound(target)])
            ]
        ]
        overwriteElements.forEach[
            if (overwrites instanceof FDCompoundOverwrites)
                (overwrites as FDCompoundOverwrites).fields.forEach[validateFieldUnionDeployments(it)]
        ]
    }

    private def void validateFieldUnionDeployments(FDField field)
    {
        if (isUnion(field.target)) {
            validateUnionDeployment(field)
        }
        val overwrites = (field as FDOverwriteElement).overwrites
        if (overwrites instanceof FDCompound) {
            overwrites.fields.forEach[
                validateFieldUnionDeployments(it)
            ]
        }
    }

    private def validateUnionDeployment(FDElement fdString)
    {
        val String maxLengthName = "SomeIpUnionMaxLength"
        val String lengthWidthName = "SomeIpUnionLengthWidth"

        val FDPropertySet properties =
            if (fdString instanceof FDOverwriteElement && (fdString as FDOverwriteElement).overwrites !== null)
                (fdString as FDOverwriteElement).overwrites.properties
            else
                fdString.properties

        val propSomeIpMaxLength = properties.items.findFirst[it.decl.name == maxLengthName]
        val propSomeIpLengthWidth = properties.items.findFirst[it.decl.name == lengthWidthName]

        var someIpLength = getInteger(propSomeIpMaxLength)
        var someIpLengthWidth = getInteger(propSomeIpLengthWidth)

        if (someIpLengthWidth !== null && someIpLengthWidth == 0)
        {
            // if lengthwidth = 0 the maxlength must be set >= 0
            //
            if (someIpLength === null || someIpLength < 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                    "Union deployment specifies 'SomeIpUnionLengthWidth = 0', but has no 'SomeIpUnionMaxLength >= 0' specified.",
                    propSomeIpLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Various
    ///////////////////////////////////////////////////////////////////////////

    private def validateDeploymentProperties()
    {
        val fdTypeDeployments = new ArrayList<FDTypeDefinition>

        // Type collections
        for (typeCollection : fdTypeCollections)
            fdTypeDeployments.addAll(typeCollection.types)

        // Interface local types
        for (fdInterface : fdInterfaces)
            fdTypeDeployments.addAll(fdInterface.types)

        for (fdType : fdTypeDeployments)
        {
            if (!(fdType instanceof FDArray))
            {
                fdType.properties.items.forEach[prop|
                    // This warning actually will never trigger, because the general Franca/FDepl validation
                    // already disallows to specify 'SomeIpArray' deployment properties for none array types.
                    // However, for safety reasons this warning is though checked here as well, in case
                    // this code is invoked without a prior general validation.
                    //
                    val propName = prop.decl.name
                    if (propName !== null && propName.startsWith("SomeIpArray"))
                    {
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Array deployment used for none array type.",
                            prop, null, -1, null, null)
                        diagnostics.add(diag)
                    }
                ]
            }
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    // Array
    ///////////////////////////////////////////////////////////////////////////

    private def boolean isArray(FTypedElement elm)
    {
        if (elm !== null)
        {
            if (elm.array)
                return true
            return isArray(elm.type)
        }
        return false
    }

    private def boolean isArray(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isArray(typeRef.derived)
        }
        return false
    }

    private def boolean isArray(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isArray(typ.actualType)
        }
        else if (typ instanceof FArrayType)
        {
            return true
        }
        return false
    }

    ///////////////////////////////////////////////////////////////////////////
    // Map
    ///////////////////////////////////////////////////////////////////////////

    private def boolean isMap(FTypedElement elm)
    {
        if (elm !== null)
            return isMap(elm.type)
        return false
    }

    private def boolean isMap(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isMap(typeRef.derived)
        }
        return false
    }

    private def boolean isMap(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isMap(typ.actualType)
        }
        else if (typ instanceof FMapType)
        {
            return true
        }
        return false
    }

    ///////////////////////////////////////////////////////////////////////////
    // Compound
    ///////////////////////////////////////////////////////////////////////////

    private def boolean isCompound(FTypedElement elm)
    {
        if (elm !== null)
            return isCompound(elm.type)
        return false
    }

    private def boolean isCompound(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isCompound(typeRef.derived)
        }
        return false
    }

    private def boolean isCompound(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isCompound(typ.actualType)
        }
        else if (typ instanceof FCompoundType)
        {
            return true
        }
        return false
    }

    ///////////////////////////////////////////////////////////////////////////
    // Union
    ///////////////////////////////////////////////////////////////////////////

    private def isUnion(FTypedElement elm)
    {
        if (elm !== null)
            return isUnion(elm.type)
        return false
    }

    private def boolean isUnion(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isUnion(typeRef.derived)
        }
        return false
    }

    private def boolean isUnion(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isUnion(typ.actualType)
        }
        else if (typ instanceof FUnionType)
        {
            return true
        }
        return false
    }

    ///////////////////////////////////////////////////////////////////////////
    // ByteBuffer
    ///////////////////////////////////////////////////////////////////////////

    private def isByteBuffer(FTypedElement elm)
    {
        if (elm !== null)
            return isByteBuffer(elm.type)
        return false
    }

    private def boolean isByteBuffer(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isByteBuffer(typeRef.derived)
            if (typeRef.predefined !== null && typeRef.predefined == FBasicTypeId.BYTE_BUFFER)
                return true
        }
        return false
    }

    private def boolean isByteBuffer(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isByteBuffer(typ.actualType)
        }
        return false
    }

    ///////////////////////////////////////////////////////////////////////////
    // String
    ///////////////////////////////////////////////////////////////////////////

    private def isString(FTypedElement elm)
    {
        if (elm !== null)
            return isString(elm.type)
        return false
    }

    private def boolean isString(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return isString(typeRef.derived)
            if (typeRef.predefined !== null && typeRef.predefined == FBasicTypeId.STRING)
                return true
        }
        return false
    }

    private def boolean isString(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return isString(typ.actualType)
        }
        return false
    }

    private def validateCompleteInterfaceDeployments(FDInterface fdInterface)
    {
        val FInterface fInterface = fdInterface.target
        if (fInterface !== null)
        {
            fInterface.attributes.forEach[fAttr|
                if (fdInterface.attributes.findFirst[fdAttr|fAttr.equals(fdAttr.target)] === null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for attribute \"" + fAttr.name + "\".",
                        fAttr, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]

            fInterface.broadcasts.forEach[fBroadcast|
                if (fdInterface.broadcasts.findFirst[fdBroadcast|fBroadcast.equals(fdBroadcast.target)] === null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for broadcast \"" + fBroadcast.name + "\".",
                        fBroadcast, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]

            fInterface.methods.forEach[fMethod|
                if (fdInterface.methods.findFirst[fdMethod|fMethod.equals(fdMethod.target)] === null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for method \"" + fMethod.name + "\".",
                        fMethod, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]
        }
    }

    private def validateCorePropertyDeployments()
    {
        fdTypeCollections.forEach[types.forEach[validateCoreProperties(it)]]
        fdInterfaces.forEach[validateInterfaceCoreProperties(it)]
    }

    private def validateInterfaceCoreProperties(FDInterface fdInterface)
    {
        validateCoreProperties(fdInterface)

        fdInterface.types.forEach[validateCoreProperties(it)]
        fdInterface.attributes.forEach[validateCoreProperties(it)]
        fdInterface.methods.forEach[
            validateCoreProperties(it)
            if (inArguments !== null)
                inArguments.arguments.forEach[validateCoreProperties(it)]
            if (outArguments !== null)
                outArguments.arguments.forEach[validateCoreProperties(it)]
        ]
        fdInterface.broadcasts.forEach[
            validateCoreProperties(it)
            if (outArguments !== null)
                outArguments.arguments.forEach[
                    validateCoreProperties(it)
                ]
        ]
    }

    private def void validateCoreProperties(FDElement fdElement)
    {
        validateCoreProperty(fdElement.properties, fdElement)

        if (fdElement instanceof FDEnumeration)
        {
            fdElement.enumerators.forEach[validateCoreProperties(it)]
        }
        else if (fdElement instanceof FDCompound)
        {
             fdElement.fields.forEach[validateCoreProperties(it)]
        }
        else if (fdElement instanceof FDOverwriteElement)
        {
            val overwrites = fdElement.overwrites
            validateCoreProperty(overwrites?.properties, fdElement)

            if (overwrites instanceof FDCompoundOverwrites)
            {
                overwrites.fields.forEach[validateCoreProperties(it)]
            }
            else if (overwrites instanceof FDEnumerationOverwrites)
            {
                overwrites.enumerators.forEach[validateCoreProperties(it)]
            }
        }
    }

    private def void validateCoreProperty(FDPropertySet fdPropSet, FDElement fdElement)
    {
        if (fdPropSet !== null)
        {
            fdPropSet.items.forEach[
                val spec = decl.eContainer?.eContainer
                val name = if (spec instanceof FDSpecificationImpl)
                               spec.name
                           else
                               null
                if (name !== null && name.contains(CORE_SPECIFICATION_TYPE))
                {
                    val warning = "Core deployment property \"" + decl.name + "\" used by \"" + getName(fdElement) + "\" within in a SOME/IP deployment."
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING, warning, it, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]
        }
    }

    private def validateInterface(FDInterface fdInterface)
    {
        var methodIds = new HashMap<Integer, ArrayList<FDProperty>>
        var eventIds = new HashMap<Integer, ArrayList<FDProperty>>
        var eventGroupIds = new HashMap<Integer, ArrayList<FDValue>>
        var selectiveBroadcastEventGroupIds = new HashMap<Integer, ArrayList<FDValue>>

        validateInterfaceAttributes(fdInterface, methodIds, eventIds, eventGroupIds)
        validateInterfaceMethods(fdInterface, methodIds)
        validateInterfaceBroadcasts(fdInterface, eventIds, eventGroupIds, selectiveBroadcastEventGroupIds)

        allMethodIds.put(fdInterface, methodIds)
        allEventIds.put(fdInterface, eventIds)
        allEventGroupIds.put(fdInterface, eventGroupIds)
        allSelectiveBroadcastEventGroupIds.put(fdInterface, selectiveBroadcastEventGroupIds)
    }

    private def getDeploymentForInterface(FInterface fInterface, FDInterface fdSuperInterface)
    {
        for (fdInterface : fdInterfaces)
        {
            if (fdInterface.target !== null && fdInterface.target !== null && fdInterface.target == fInterface)
                return fdInterface
        }

        if (!missingInterfaceDeployment.contains(fInterface))
        {
            missingInterfaceDeployment.add(fInterface)
            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                "No deployment for interface \"" + fInterface.name + "\".",
                fdSuperInterface, null, -1, null, null)
            diagnostics.add(diag)
        }

        return null
    }

    private def void getInterfaceExtensionIds(
        FDInterface fdInterface,
        HashMap<Integer, ArrayList<FDProperty>> interfaceIdProps,
        HashMap<FDInterface, HashMap<Integer, ArrayList<FDProperty>>> allInterfaceIdProps
    )
    {
        if (fdInterface.target !== null)
        {
            val fBaseInterface = fdInterface.target.base
            if (fBaseInterface !== null)
            {
                val fdBaseInterface = getDeploymentForInterface(fBaseInterface, fdInterface)
                if (fdBaseInterface !== null)
                {
                    val baseInterfaceIdProps = allInterfaceIdProps.get(fdBaseInterface)
                    if (baseInterfaceIdProps !== null)
                    {
                        for (idProps : baseInterfaceIdProps.entrySet)
                        {
                            var props = interfaceIdProps.get(idProps.key)
                            if (props === null)
                            {
                                // NOTE: Put a clone(!) of the 'idProps' into the list. Because we have to deal
                                // with interfaces which are used as base interface for several other interfaces,
                                // the 'idProps' of such a (base) interface must not get added via reference to
                                // 'interfaceIdProps'. Otherwise we risk 'ConcurrentModificationException' if
                                // the base interface is processed again in the context of a different interface.
                                //
                                interfaceIdProps.put(idProps.key, idProps.value.clone as ArrayList<FDProperty>)
                            }
                            else
                                props.addAll(idProps.value)
                        }
                    }

                    getInterfaceExtensionIds(fdBaseInterface, interfaceIdProps, allInterfaceIdProps)
                }
            }
        }
    }

    private def void getInterfaceExtensionEventGroupIds(
        FDInterface fdInterface,
        HashMap<Integer, ArrayList<FDValue>> interfaceIdEventGroups,
        HashMap<FDInterface, HashMap<Integer, ArrayList<FDValue>>> allInterfaceIdEventGroups
    )
    {
        if (fdInterface.target !== null)
        {
            val fBaseInterface = fdInterface.target.base
            if (fBaseInterface !== null)
            {
                val fdBaseInterface = getDeploymentForInterface(fBaseInterface, fdInterface)
                if (fdBaseInterface !== null)
                {
                    val baseInterfaceIdEventGroups = allInterfaceIdEventGroups.get(fdBaseInterface)
                    if (baseInterfaceIdEventGroups !== null)
                    {
                        for (idEventGroups : baseInterfaceIdEventGroups.entrySet)
                        {
                            var eventGroups = interfaceIdEventGroups.get(idEventGroups.key)
                            if (eventGroups === null)
                            {
                                // NOTE: Put a clone(!) of the 'idProps' into the list. Because we have to deal
                                // with interfaces which are used as base interface for several other interfaces,
                                // the 'idProps' of such a (base) interface must not get added via reference to
                                // 'interfaceIdProps'. Otherwise we risk 'ConcurrentModificationException' if
                                // the base interface is processed again in the context of a different interface.
                                //
                                interfaceIdEventGroups.put(idEventGroups.key, idEventGroups.value.clone as ArrayList<FDValue>)
                            }
                            else
                                eventGroups.addAll(idEventGroups.value)
                        }
                    }

                    getInterfaceExtensionEventGroupIds(fdBaseInterface, interfaceIdEventGroups, allInterfaceIdEventGroups)
                }
            }
        }
    }

    /**
     * - Every method, getter and setter must have a unique 'SomeIpMethodID' / 'SomeIpGetterID' / 'SomeIpSetterID'
     *   within the interface and its base interfaces.
     *
     * - Every broadcast and attribute notifier must have a unique 'SomeIpEventID' / 'SomeIpNotifierID'
     *   within the interface and its base interfaces.
     *
     * - Every 'selective' broadcast must use a unique event group
     *   within the interface and its base interfaces.
     */
    private def validateIds(FDInterface fdInterface)
    {
        // NOTE: Must use a 'clone' of the lists to handle base interfaces which are used from different super interfaces
        var methodIds = allMethodIds.get(fdInterface).clone as HashMap<Integer, ArrayList<FDProperty>>
        var eventIds = allEventIds.get(fdInterface).clone as HashMap<Integer, ArrayList<FDProperty>>
        var eventGroupIds = allEventGroupIds.get(fdInterface).clone as HashMap<Integer, ArrayList<FDValue>>
        var selectiveBroadcastEventGroupIds = allSelectiveBroadcastEventGroupIds.get(fdInterface).clone as HashMap<Integer, ArrayList<FDValue>>

        getInterfaceExtensionIds(fdInterface, methodIds, allMethodIds)
        getInterfaceExtensionIds(fdInterface, eventIds, allEventIds)
        getInterfaceExtensionEventGroupIds(fdInterface, eventGroupIds, allEventGroupIds)
        getInterfaceExtensionEventGroupIds(fdInterface, selectiveBroadcastEventGroupIds, allSelectiveBroadcastEventGroupIds)

        // Method ID values for "SomeIpGetterID", "SomeIpSetterID" and "SomeIpMethodID" must be unique for an interface and all base interfaces
        //
        for (idProps : methodIds.entrySet)
        {
            val props = idProps.value
            if (props.size > 1)
            {
                for (prop : props)
                {
                    // Avoid duplicate diagnostics - maybe happen for base interfaces which are causing messages in different super interfaces
                    //
                    if (!methodIdDiagnostics.contains(prop))
                    {
                        methodIdDiagnostics.add(prop)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Interface \"" + getInterfaceName(fdInterface) + "\" uses method ID " + idProps.key + " for multiple methods and/or attribute get/set functions.",
                            prop, null, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
            }
        }

        // Event ID values for "SomeIpNotifierID" and "SomeIpEventID" must be unique for an interface and all base interfaces.
        //
        for (idProps : eventIds.entrySet)
        {
            var props = idProps.value
            if (props.size > 1)
            {
                for (prop : props)
                {
                    // Avoid duplicate diagnostics - maybe happen for base interfaces which are causing messages in different super interfaces
                    //
                    if (!eventIdDiagnostics.contains(prop))
                    {
                        eventIdDiagnostics.add(prop)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Interface \"" + getInterfaceName(fdInterface) + "\" uses event ID " + idProps.key + " for multiple broadcasts and/or attribute notifications.",
                            prop, null, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
            }
        }

        // Event Group ID values for selective broadcasts must be unique for an interface and all base interfaces.
        //
        for (idEventGroups : selectiveBroadcastEventGroupIds.entrySet)
        {
            // The current 'event group ID' is to be searched in 'eventGroupIds' rather than 'selectiveBroadcastEventGroupIds' because the 'event group ID'
            // must be unique amongst all the used event group IDs in the interface, not just those event group IDs which are used for the 'selective broadcasts'
            //
            var props = eventGroupIds.get(idEventGroups.key)
            if (props !== null && props.size > 1)
            {
                for (prop : props)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Interface \"" + getInterfaceName(fdInterface) + "\" uses event group " + idEventGroups.key + " for multiple selective broadcasts and/or attribute notifications.",
                        prop, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
        }
    }

    /**
     * - Every attribute must have at least one of [SomeIpGetterID, SomeIpSetterID, SomeIpNotifierID] specified.
     *
     * - If an attribute is declared as 'readonly', it must *not* have a 'SomeIpSetterID' specification.
     *
     * - If an attribute is declared as 'noSubscriptions', it must *not* have a 'SomeIpNotifierID' specification.
     *
     * - If an attribute has a 'SomeIpNotifierID' specification, the attribute must also have a valid event group
     *   specified within the 'SomeIpNotifierEventGroups' setting.
     */
    private def validateInterfaceAttributes(
        FDInterface fdInterface,
        HashMap<Integer, ArrayList<FDProperty>> methodIds,
        HashMap<Integer, ArrayList<FDProperty>> eventIds,
        HashMap<Integer, ArrayList<FDValue>> eventGroupIds)
    {
        for (attribute : fdInterface.attributes)
        {
            val propSomeIpGetterID = attribute.properties.items.findFirst[it.decl.name == "SomeIpGetterID"]
            val propSomeIpSetterID = attribute.properties.items.findFirst[it.decl.name == "SomeIpSetterID"]
            val propSomeIpNotifierID = attribute.properties.items.findFirst[it.decl.name == "SomeIpNotifierID"]

            val getterId = getId(propSomeIpGetterID)
            val setterId = getId(propSomeIpSetterID)
            val notifierId = getId(propSomeIpNotifierID)

            var validGetterId = false
            var validSetterId = false
            var validNotifierId = false

            if (getterId !== null)
            {
                // 'SomeIpGetterID = 0' is allowed, if the attribute is not marked as 'noread'
                if (getterId > 0 || (getterId == 0 && !attribute.target.noRead))
                    validGetterId = true
            }

            if (setterId !== null)
            {
                // 'SomeIpSetterID = 0' is allowed, if the attribute is marked as 'readonly'
                if (setterId > 0 || (setterId == 0 && attribute.target.isReadonly))
                    validSetterId = true
            }

            if (notifierId !== null)
            {
                // 'SomeIpNotifierID = 0' is allowed, if the attribute is marked as 'noSubscriptions'
                if (notifierId > 0 || (notifierId == 0 && attribute.target.isNoSubscriptions))
                    validNotifierId = true
            }

            // It isn't valid to specify 'SomeIpGetterID = 0' + 'SomeIpSetterID = 0' + 'SomeIpNotifierID = 0'
            if (((setterId !== null && setterId == 0) &&
                (getterId !== null && getterId == 0) &&
                (notifierId !== null && notifierId == 0))) {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Attribute \"" + getAttributeName(attribute) + "\" has " +
                    "'SomeIpGetterID' and 'SomeIpSetterID' and 'SomeIpNotifierID' " +
                    "all set to zero.",
                    attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                diagnostics.add(diag)
            }
            // The SomeIp deployment for attributes needs to have at least one of the following properties specified
            //
            else if (!validGetterId && !validSetterId && !validNotifierId)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Attribute \"" + getAttributeName(attribute) + "\" has no valid 'SomeIpGetterID', 'SomeIpSetterID' or 'SomeIpNotifierID' specified.",
                    attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                diagnostics.add(diag)
            }
            else
            {
                if (!validGetterId)
                {
                    if (getterId !== null && getterId == 0 && attribute.target.noRead)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has a 'SomeIpGetterID = 0' specified, but the associated attribute in the interface definition is declared as 'noRead'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
                else
                {
                    if (attribute.target.noRead && getterId > 0)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has a 'SomeIpGetterID' specified, but the associated attribute in the interface definition is declared as 'noRead'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                    else if (getterId > 0 && !(getterId >= MIN_METHOD_ID_VALUE && getterId <= MAX_METHOD_ID_VALUE))
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + attrName + "\" declares a 'SomeIpGetterID' not within range " + MIN_METHOD_ID_VALUE + " - " + MAX_METHOD_ID_VALUE + ".",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // If there is no 'SomeIpSetterID' specified, check whether the respective attribute is declared as 'readonly'
                //
                if (!validSetterId)
                {
                    if (!attribute.target.readonly)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has no valid 'SomeIpSetterID' specified, but the associated attribute in the interface definition is not declared as 'readonly'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
                else
                {
                    if (attribute.target.readonly && setterId > 0)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has a 'SomeIpSetterID' specified, but the associated attribute in the interface definition is declared as 'readonly'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                    else if (setterId > 0 && !(setterId >= MIN_METHOD_ID_VALUE && setterId <= MAX_METHOD_ID_VALUE))
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + attrName + "\" declares a 'SomeIpSetterID' not within range " + MIN_METHOD_ID_VALUE + " - " + MAX_METHOD_ID_VALUE + ".",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // If there is no 'SomeIpNotifierID' specified, check whether the associated attribute is declared as 'noSubscriptions'
                //
                if (!validNotifierId)
                {
                    if (!attribute.target.noSubscriptions)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has no valid 'SomeIpNotifierID' specified, but the associated attribute in the interface definition is not declared as 'noSubscriptions'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
                else
                {
                    if (attribute.target.noSubscriptions && notifierId > 0)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                            "Attribute \"" + attrName + "\" has a 'SomeIpNotifierID' specified, but the associated attribute in the interface definition is declared as 'noSubscriptions'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                    else if (notifierId > 0 && !(notifierId >= MIN_EVENT_ID_VALUE && notifierId <= MAX_EVENT_ID_VALUE))
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + attrName + "\" declares a 'SomeIpNotifierID' not within range " + MIN_EVENT_ID_VALUE + " - " + MAX_EVENT_ID_VALUE  + ".",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // If there is a 'SomeIpNotifierID' specified, check whether there is also a valid event group specified.
                //
                if (validNotifierId)
                {
                    var createdWarning = false
                    var validEventGroup = false
                    var propEventGroups = attribute.properties.items.findFirst[it.decl.name == "SomeIpNotifierEventGroups"]
                    if (propEventGroups === null)
                        propEventGroups = attribute.properties.items.findFirst[it.decl.name == "SomeIpEventGroups"]
                    if (propEventGroups !== null)
                    {
                        for (fdEventGroup : propEventGroups.value.array.values)
                        {
                            if (fdEventGroup instanceof FDInteger)
                            {
                                var eventGroupId = fdEventGroup.value
                                if (eventGroupId >= MIN_EVENT_GROUP_VALUE && eventGroupId <= MAX_EVENT_GROUP_VALUE)
                                {
                                    var props = eventGroupIds.get(eventGroupId)
                                    if (props === null) {
                                        props = new ArrayList<FDValue>
                                        eventGroupIds.put(eventGroupId, props)
                                    }
                                    props.add(fdEventGroup)
                                    validEventGroup = true
                                }
                                else
                                {
                                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                        "Attribute \"" + getAttributeName(attribute) + "\" contains an event group not within range " + MIN_EVENT_GROUP_VALUE + " - " + MAX_EVENT_GROUP_VALUE + ".",
                                        fdEventGroup, null, -1, null, null)
                                    diagnostics.add(diag)
                                    createdWarning = true
                                }
                            }
                        }
                    }
                    if (!validEventGroup && !createdWarning)
                    {
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + getAttributeName(attribute) + "\" has no valid 'SomeIpNotifierEventGroups' specified.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // Duplicate 'SomeIpGetterId = 0' are valid and Ok.
                if (validGetterId && getterId > 0)
                {
                    var id = (propSomeIpGetterID.value.single as FDInteger).value
                    var props = methodIds.get(id)
                    if (props === null) {
                        props = new ArrayList<FDProperty>
                        methodIds.put(id, props)
                    }
                    props.add(propSomeIpGetterID)
                }

                // Duplicate 'SomeIpSetterId = 0' are valid and Ok because a interface could contain
                // multiple readonly attributes with SomeIpSetterId set to 0
                if (validSetterId && setterId > 0)
                {
                    var id = (propSomeIpSetterID.value.single as FDInteger).value
                    var props = methodIds.get(id)
                    if (props === null) {
                        props = new ArrayList<FDProperty>
                        methodIds.put(id, props)
                    }
                    props.add(propSomeIpSetterID)
                }

                // Duplicate 'SomeIpNotifierId = 0' are valid and Ok because a interface could contain
                // multiple noSubscription attributes with SomeIpNotifierId set to 0
                if (validNotifierId && notifierId > 0)
                {
                    var id = (propSomeIpNotifierID.value.single as FDInteger).value
                    var props = eventIds.get(id)
                    if (props === null) {
                        props = new ArrayList<FDProperty>
                        eventIds.put(id, props)
                    }
                    props.add(propSomeIpNotifierID)
                }

                if (attribute.target.noRead)
                {
                    var attrName = getAttributeName(attribute)
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Deprecated: Attribute \"" + attrName + "\" is declared as 'noRead'.",
                        attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                    diagnostics.add(diag)
                }

                val propEventGroups = attribute.properties.items.findFirst[it.decl.name == "SomeIpEventGroups"]
                if (propEventGroups !== null)
                {
                    var attrName = getAttributeName(attribute)
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Deprecated: Attribute \"" + attrName + "\" is using 'SomeIpEventGroups', use 'SomeIpNotifierEventGroups'.",
                        attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                    diagnostics.add(diag)
                }
            }
        }
    }

    /**
     * - Every method must have a 'SomeIpMethodID [1..32767]' specified.
     */
    private def validateInterfaceMethods(FDInterface fdInterface, HashMap<Integer, ArrayList<FDProperty>> methodIds)
    {
        for (FDMethod fdMethod : fdInterface.methods)
        {
            var propMethodId = fdMethod.properties.items.findFirst[it.decl.name == "SomeIpMethodID"]
            if (isValidId(propMethodId))
            {
                var methodId = (propMethodId.value.single as FDInteger).value
                if (methodId >= MIN_METHOD_ID_VALUE && methodId <= MAX_METHOD_ID_VALUE)
                {
                    var props = methodIds.get(methodId)
                    if (props === null) {
                        props = new ArrayList<FDProperty>
                        methodIds.put(methodId, props)
                    }
                    props.add(propMethodId)
                }
                else
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Method ID for \"" + getMethodName(fdMethod) + "\" is not within range " + MIN_METHOD_ID_VALUE + " - " + MAX_METHOD_ID_VALUE + ".",
                        fdMethod, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
            else
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Method ID for \"" + getMethodName(fdMethod) + "\" is not valid. Specify a value within range " + MIN_METHOD_ID_VALUE + " - " + MAX_METHOD_ID_VALUE + ".",
                    fdMethod, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    /**
     * - Every broadcast must have a 'SomeIpEventID [32769..65534]' specified.
     *
     * - Every broadcast must have a valid event group specified within the 'SomeIpEventGroups' setting.
     *
     */
    private def validateInterfaceBroadcasts(
        FDInterface fdInterface,
        HashMap<Integer, ArrayList<FDProperty>> eventIds,
        HashMap<Integer, ArrayList<FDValue>> eventGroupIds,
        HashMap<Integer, ArrayList<FDValue>> selectiveBroadcastEventGroupIds
    )
    {
        for (FDBroadcast fdBroadcast : fdInterface.broadcasts)
        {
            // Every broadcast must have a 'SomeIpEventID [32769..65534]' specified.
            //
            var propEventId = fdBroadcast.properties.items.findFirst[it.decl.name == "SomeIpEventID"]
            if (isValidId(propEventId))
            {
                var eventId = (propEventId.value.single as FDInteger).value
                if (eventId >= MIN_EVENT_ID_VALUE && eventId <= MAX_EVENT_ID_VALUE)
                {
                    var props = eventIds.get(eventId)
                    if (props === null) {
                        props = new ArrayList<FDProperty>
                        eventIds.put(eventId, props)
                    }
                    props.add(propEventId)
                }
                else
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Event ID for broadcast \"" + getBroadcastName(fdBroadcast) + "\" is not within range " + MIN_EVENT_ID_VALUE + " - " + MAX_EVENT_ID_VALUE + ".",
                        fdBroadcast, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
            else
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Event ID for broadcast \"" + getBroadcastName(fdBroadcast) + "\" is not valid. Specify a value within range " + MIN_EVENT_ID_VALUE + " - " + MAX_EVENT_ID_VALUE + ".",
                    fdBroadcast, null, -1, null, null)
                diagnostics.add(diag)
            }

            // Every broadcast must have a valid event group specified within the 'SomeIpEventGroups' setting.
            //
            var createdWarning = false
            var validEventGroup = false
            var propEventGroups = fdBroadcast.properties.items.findFirst[it.decl.name == "SomeIpEventGroups"]
            if (propEventGroups !== null)
            {
                for (fdEventGroup : propEventGroups.value.array.values)
                {
                    if (fdEventGroup instanceof FDInteger)
                    {
                        var eventGroupId = fdEventGroup.value
                        if (eventGroupId >= MIN_EVENT_GROUP_VALUE && eventGroupId <= MAX_EVENT_GROUP_VALUE)
                        {
                            var props = eventGroupIds.get(eventGroupId)
                            if (props === null) {
                                props = new ArrayList<FDValue>
                                eventGroupIds.put(eventGroupId, props)
                            }
                            props.add(fdEventGroup)
                            validEventGroup = true

                            // Save the event group IDs of 'selective' broadcasts.
                            if (fdBroadcast.target.isSelective)
                            {
                                props = selectiveBroadcastEventGroupIds.get(eventGroupId)
                                if (props === null) {
                                    props = new ArrayList<FDValue>
                                    selectiveBroadcastEventGroupIds.put(eventGroupId, props)
                                }
                                props.add(fdEventGroup)
                            }
                        }
                        else
                        {
                            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                "Broadcast \"" + getBroadcastName(fdBroadcast) + "\" contains an event group not within range " + MIN_EVENT_GROUP_VALUE + " - " + MAX_EVENT_GROUP_VALUE + ".",
                                fdEventGroup, null, -1, null, null)
                            diagnostics.add(diag)
                            createdWarning = true
                        }
                    }
                }
            }
            if (!validEventGroup && createdWarning)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Broadcast \"" + getBroadcastName(fdBroadcast) + "\" has no valid event group specified.",
                    fdBroadcast, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    private def getName(FDElement fdElement)
    {
        if (fdElement instanceof FDInterface)       return getInterfaceName(fdElement)
        if (fdElement instanceof FDAttribute)       return getAttributeName(fdElement)
        if (fdElement instanceof FDMethod)          return getMethodName(fdElement)
        if (fdElement instanceof FDBroadcast)       return getBroadcastName(fdElement)
        if (fdElement instanceof FDEnumeration)     return getEnumerationName(fdElement)
        if (fdElement instanceof FDField)           return getFieldName(fdElement)
        if (fdElement instanceof FDArgument)        return getArgumentName(fdElement)
        return fdElement.toString
    }

    private def getInterfaceName(FDInterface fdInterface)
    {
        if (fdInterface === null || fdInterface.target === null)
            return null
        return fdInterface.target.name
    }

    private def getAttributeName(FDAttribute attribute)
    {
        if (attribute === null || attribute.target === null)
            return null
        return attribute.target.name
    }

    private def getMethodName(FDMethod method)
    {
        if (method === null || method.target === null)
            return null
        return method.target.name
    }

    private def getBroadcastName(FDBroadcast broadcast)
    {
        if (broadcast === null || broadcast.target === null)
            return null
        return broadcast.target.name
    }

    private def getArgumentName(FDArgument fdArgument)
    {
        if (fdArgument === null || fdArgument.target === null)
            return null
        return fdArgument.target.name
    }

    private def getEnumerationName(FDEnumeration fdEnumeration)
    {
        if (fdEnumeration === null || fdEnumeration.target === null)
            return null
        return fdEnumeration.target.name
    }

    private def getFieldName(FDField fdField)
    {
        if (fdField === null || fdField.target === null)
            return null
        return fdField.target.name
    }

//    private def getTypeName(FDElement element)
//    {
//        if (element instanceof FDAttribute)
//        {
//            return getTypeName(element.target?.type)
//        }
//        return element.toString
//    }

    private def getTypeName(FTypeRef type)
    {
        return type?.derived?.name
    }

    private def getFullTypeName(FTypeRef typeRef)
    {
        var name = getTypeName(typeRef)
        var type = typeRef.derived
        if (type !== null)
        {
            var typeContainer = type.eContainer
            if (typeContainer !== null)
            {
                if (typeContainer instanceof FInterface)
                {
                    name = (typeContainer.eContainer as FModel).name + "." + typeContainer.name + "." + name
                }
                else if (typeContainer instanceof FTypeCollection)
                {
                    name = (typeContainer.eContainer as FModel).name + "." + typeContainer.name + "." + name
                }
                else if (typeContainer instanceof FCompoundType)
                    name = typeContainer.name + "." + name
            }
        }
        return name
    }

    private def isValidId(FDProperty prop)
    {
        if (prop === null || prop.value === null)
            return false
        if (!(prop.value.single instanceof FDInteger))
            return false
        if ((prop.value.single as FDInteger).value <= 0)
            return false
        return true
    }

    private def getId(FDProperty prop)
    {
        return getInteger(prop)
    }

    private def getInteger(FDProperty prop)
    {
        if (prop === null || prop.value === null)
            return null
        if (!(prop.value.single instanceof FDInteger))
            return null
        return (prop.value.single as FDInteger).value
    }

//    private def String getFullName(FInterface intf)
//    {
//        if (intf === null)
//            return ""
//        return (intf.eContainer as FModel).name + "." + intf.name
//    }

    private def validateImports()
    {
        allFDepls.forEach[it.checkMissingDeploymentImports]
    }

    private def checkMissingDeploymentImports(FDModel fdModel)
    {
        /*
         * recursive flag
         *  true    - recursively get the list of imported FDEPLs for the current FDEPL file
         *          - recursively get the list of imported FIDLs for the current FDEPL file
         *          - for each FIDL found (in any of the files), check if there is an expected FDEPL imported (in any of the files)
         *
         *  false   - get the list of imported FDEPLs only from the current FDEPL file
         *          - get the list of imported FIDLs from the current FDEPL file and from the imports of the imported FIDLs (but not recursively)
         *          - for each FIDL found, check if there is an expected FDEPL imported in the current FDEPL file
         */
        var recursive = false

        if (!recursive)
        {
            // this version of the check does not make sense for the FDEPLs which contain 'provider' only. respectively
            // the check make sense only for files which deploy an interface or a type collection.
            if (fdModel.deployments.findFirst[(it instanceof FDInterface) || (it instanceof FDTypes)] === null)
                return
        }

        var fdeplUris = getImportedFDepls(fdModel, recursive)
        var fidlUris = getImportedFidlsUpToLevel2(fdModel, recursive)
        val u = java.net.URI.create(fdModel.eResource.URI.toString).normalize.toString
        for (fidl : fidlUris)
        {
            val correspondingFdeplImportSpec = java.net.URI.create(fidl.toString).normalize.toString.replaceFidlWithFDeplExtension

            // skip the FIDL which corresponds to the FDEPL which we are validating right now
            if (!u.equals(correspondingFdeplImportSpec))
            {
                if (fdeplUris.findFirst[it.toString.equals(correspondingFdeplImportSpec)] === null)
                {
                    val fidlPath = getDisplayPath(fidl)
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Deployment references \"" + fidlPath + "\" without referencing expected deployment file \"" + fidlPath.replaceFidlWithFDeplExtension + "\".",
                        fdModel, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
        }
    }

    private def validateProviderInstanceDeployments()
    {
        allFDepls.forEach[fdModel|
            if (!ProviderUtils.getProviders(fdModel).empty)
            {
                var fdeplUris = getImportedFDepls(fdModel, false)
                var fidlUris = getImportedFidls(fdModel)
                val u = java.net.URI.create(fdModel.eResource.URI.toString).normalize.toString
                for (fidl : fidlUris)
                {
                    val correspondingFdeplImportSpec = java.net.URI.create(fidl.toString).normalize.toString.replaceFidlWithFDeplExtension

                    // skip the FIDL which corresponds to the FDEPL which we are validating right now
                    if (!u.equals(correspondingFdeplImportSpec))
                    {
                        if (fdeplUris.findFirst[it.toString.equals(correspondingFdeplImportSpec)] === null)
                        {
                            val fidlPath = getDisplayPath(fidl)
                            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                "Deployment references \"" + fidlPath + "\" without referencing expected deployment file \"" + fidlPath.replaceFidlWithFDeplExtension + "\".",
                                fdModel, null, -1, null, null)
                            diagnostics.add(diag)
                        }
                    }
                }
            }
        ]

    }

    private def Collection<URI> getImportedFDepls(FDModel fdModel, boolean recursive)
    {
        val uris = new ArrayList<URI>
        for (import : fdModel.imports)
        {
            // Process only FDEPL files
            if (import.importURI.endsWith(FDEPL_FILE_EXTENSION_SUFFIX))
            {
                // Skip Deployment Specification files
                if (!import.importURI.endsWith(DEPLOYMENT_SPECIFICATION_FILE_SUFFIX))
                {
                    var importUri = getAbsoluteUri(fdModel, import.importURI)
                    if (!uris.contains(importUri))
                    {
                        var fdImportedModel = getFDModel(importUri)
                        if (fdImportedModel !== null)
                        {
                            uris.add(importUri)
                            if (recursive)
                            {
                                getImportedFDepls(fdImportedModel, recursive).forEach[
                                    if (!uris.contains(it))
                                        uris.add(it)
                                ]
                            }
                        }
                    }
                }
            }
        }
        return uris
    }

    private def FDModel getFDModel(URI importUri)
    {
        return allFDepls.findFirst[eResource.URI == importUri]
    }

    private def FModel getFModel(URI importUri, ResourceSet resourceSet)
    {
        var fidls = new ArrayList<FModel>
        for (Resource resource : resourceSet.resources)
        {
            for (EObject eObject : resource.getContents())
            {
                if (eObject instanceof FModel)
                    fidls.add(eObject)
            }
        }
        return fidls.findFirst[it.eResource.URI.equals(importUri)]
    }

    private def URI getAbsoluteUri(FDModel fdModel, String importURIStr)
    {
        return getAbsoluteUri(fdModel.eResource, importURIStr)
    }

    private def URI getAbsoluteUri(FModel fModel, String importURIStr)
    {
        return getAbsoluteUri(fModel.eResource, importURIStr)
    }

    private def URI getAbsoluteUri(Resource resource, String importURIStr)
    {
        var importUri = URI.createURI(importURIStr)
        return importUri.resolve(resource.URI)
    }

    private def Collection<URI> getImportedFidls(FDModel fdModel)
    {
        val uris = new ArrayList<URI>
        for (import : fdModel.imports)
        {
            if (import.importURI.endsWith(FIDL_FILE_EXTENSION_SUFFIX))
            {
                var importUri = getAbsoluteUri(fdModel, import.importURI)
                if (!uris.contains(importUri))
                {
                    var fImportedModel = getFModel(importUri, fdModel.eResource.resourceSet)
                    if (fImportedModel !== null)
                    {
                        uris.add(importUri)
                    }
                }
            }
        }
        return uris
    }

    private def Collection<URI> getImportedFidlsUpToLevel2(FDModel fdModel, boolean recursive)
    {
        val uris = new ArrayList<URI>
        for (import : fdModel.imports)
        {
            if (import.importURI.endsWith(FIDL_FILE_EXTENSION_SUFFIX))
            {
                var importUri = getAbsoluteUri(fdModel, import.importURI)
                if (!uris.contains(importUri))
                {
                    var fImportedModel = getFModel(importUri, fdModel.eResource.resourceSet)
                    if (fImportedModel !== null)
                    {
                        uris.add(importUri)

                        getImportedFidls(fImportedModel, recursive).forEach[
                            if (!uris.contains(it))
                                uris.add(it)
                        ]
                    }
                }
            }
        }
        return uris
    }

    private def Collection<URI> getImportedFidls(FModel fModel, boolean recursive)
    {
        val uris = new ArrayList<URI>
        for (import : fModel.imports)
        {
            if (import.importURI.endsWith(FIDL_FILE_EXTENSION_SUFFIX))
            {
                var importUri = getAbsoluteUri(fModel, import.importURI)
                if (!uris.contains(importUri))
                {
                    var fImportedModel = getFModel(importUri, fModel.eResource.resourceSet)
                    if (fImportedModel !== null)
                    {
                        uris.add(importUri)
                        if (recursive)
                        {
                            getImportedFidls(fImportedModel, recursive).forEach[
                                if (!uris.contains(it))
                                    uris.add(it)
                            ]
                        }
                    }
                }
            }
        }
        return uris
    }

    private def replaceFidlWithFDeplExtension(String filePath)
    {
        return filePath.replaceFirst("\\" + FIDL_FILE_EXTENSION_SUFFIX + "$", FDEPL_FILE_EXTENSION_SUFFIX)
    }

    private def String getDisplayPath(URI uri)
    {
        var String displayPath = null
        if (uri.isPlatformResource())
            displayPath = uri.toPlatformString(true)
        if (displayPath === null)
            displayPath = uri.toFileString()
        if (displayPath === null)
            displayPath = uri.toString()
        return displayPath
    }

    private def String getEnumeratorValue(FDProperty property)
    {
        val value = property.value.single
        if (value instanceof FDGeneric)
        {
            val genericValue = value.value
            if (genericValue instanceof FDEnumerator)
                return genericValue.name
        }
        return null
    }

    private def getTargetEnumType(FDElement fdElem)
    {
        if (fdElem instanceof FDAttribute)
            return getEnum(fdElem.target)
        if (fdElem instanceof FDArgument)
            return getEnum(fdElem.target)
        if (fdElem instanceof FDField)
            return getEnum(fdElem.target)
        if (fdElem instanceof FDEnumeration)
            return getEnum(fdElem.target)
        return null
    }

//    private def FCompoundType getCompound(FTypedElement elm)
//    {
//        if (elm !== null)
//            return getCompound(elm.type)
//        return null
//    }

    private def FCompoundType getCompound(FTypeRef typeRef)
    {
        if (typeRef !== null)
        {
            if (typeRef.derived !== null)
                return getCompound(typeRef.derived)
        }
        return null
    }

    private def FCompoundType getCompound(FType typ)
    {
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType !== null)
                return getCompound(typ.actualType)
        }
        else if (typ instanceof FCompoundType)
        {
            return typ
        }
        return null
    }

//    private def FCompoundType getTargetCompoundType(FDElement fdElem)
//    {
//        if (fdElem instanceof FDAttribute)
//            return getCompound(fdElem.target)
//        if (fdElem instanceof FDArgument)
//            return getCompound(fdElem.target)
//        if (fdElem instanceof FDField)
//            return getCompound(fdElem.target)
//        return null
//    }

}
