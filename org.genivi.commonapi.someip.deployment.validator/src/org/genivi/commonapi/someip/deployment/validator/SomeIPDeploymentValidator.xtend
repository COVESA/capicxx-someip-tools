package org.genivi.commonapi.someip.deployment.validator

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
import org.franca.core.franca.FInterface
import org.franca.core.franca.FModel
import org.franca.core.franca.FType
import org.franca.core.franca.FTypeDef
import org.franca.core.franca.FTypeRef
import org.franca.core.franca.FTypedElement
import org.franca.deploymodel.dsl.fDeploy.FDArgument
import org.franca.deploymodel.dsl.fDeploy.FDArray
import org.franca.deploymodel.dsl.fDeploy.FDAttribute
import org.franca.deploymodel.dsl.fDeploy.FDBroadcast
import org.franca.deploymodel.dsl.fDeploy.FDCompound
import org.franca.deploymodel.dsl.fDeploy.FDElement
import org.franca.deploymodel.dsl.fDeploy.FDInteger
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDInterfaceInstance
import org.franca.deploymodel.dsl.fDeploy.FDMethod
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDProperty
import org.franca.deploymodel.dsl.fDeploy.FDProvider
import org.franca.deploymodel.dsl.fDeploy.FDStruct
import org.franca.deploymodel.dsl.fDeploy.FDTypeDef
import org.franca.deploymodel.dsl.fDeploy.FDTypes
import org.franca.deploymodel.dsl.fDeploy.FDUnion
import org.franca.deploymodel.dsl.fDeploy.FDValue

import static org.franca.deploymodel.dsl.fDeploy.FDeployPackage.Literals.*

class SomeIPDeploymentValidator
{
    private static String FIDL_FILE_EXTENSION_SUFFIX                = ".fidl";
    private static String FDEPL_FILE_EXTENSION_SUFFIX               = ".fdepl";
    private static String DEPLOYMENT_SPECIFICATION_FILENAME_SUFFIX  = "_deployment_spec.fdepl"
    private static String SOMEIP_SPECIFICATION_TYPE                 = "someip.deployment"

    var DiagnosticChain diagnostics
    var allMethodIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDProperty>>>
    var allEventIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDProperty>>>
    var allEventGroupIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDValue>>>
    var allSelectiveBroadcastEventGroupIds = new HashMap<FDInterface, HashMap<Integer, ArrayList<FDValue>>>
    var methodIdDiagnostics = new HashSet<FDProperty>
    var eventIdDiagnostics = new HashSet<FDProperty>
    var missingInterfaceDeployment = new HashSet<FInterface>
    var fdInterfaces = new ArrayList<FDInterface>
    var fdInterfaceInstances = new ArrayList<FDInterfaceInstance>
    var fdTypeCollections = new ArrayList<FDTypes>
    var allFDepls = new ArrayList<FDModel> // all FDModels but without "_deployment_spec.fdepl" files

    def validate(Collection<FDModel> fdepls, DiagnosticChain diagnostics)
    {
        this.diagnostics = diagnostics

        for (fdepl : fdepls)
        {
            var deplFileName = fdepl.eResource.URI.lastSegment
            if (!deplFileName.endsWith(DEPLOYMENT_SPECIFICATION_FILENAME_SUFFIX))
            {
                allFDepls.add(fdepl)
                for (fdInterface : fdepl.deployments.filter(typeof(FDInterface)))
                {
                    if (fdInterface.spec.name != null && fdInterface.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdInterfaces.add(fdInterface)
                }
                for (fdProvider : fdepl.deployments.filter(typeof(FDProvider)))
                {
                    if (fdProvider.spec.name != null && fdProvider.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdInterfaceInstances.addAll(fdProvider.instances)
                }
                for (fdTypes : fdepl.deployments.filter(typeof(FDTypes)))
                {
                    if (fdTypes.spec.name != null && fdTypes.spec.name.contains(SOMEIP_SPECIFICATION_TYPE))
                        fdTypeCollections.addAll(fdTypes)
                }
            }
        }

        for (fdInterface : fdInterfaces)
            validateInterface(fdInterface)

        for (fdInterface : fdInterfaces)
            validateIds(fdInterface)

        for (fdInterface : fdInterfaces)
            validateCompleteInterfaceDeployments(fdInterface)

        validateProviderInstanceDeployments()

        validateArrayDeployments()
        validateDeploymentProperties()

        validateImports(allFDepls)
    }

    private def validateArrayDeployments()
    {
        val fdArrays = new ArrayList<FDElement>

        // Type collections
        for (typeCollection : fdTypeCollections)
            fdArrays.addAll(typeCollection.types.filter(typeof(FDArray)))

        // Interface local types
        for (fdInterface : fdInterfaces)
            fdArrays.addAll(fdInterface.types.filter(typeof(FDArray)))

        fdArrays.forEach[fd|
            validateArrayDeployment(fd,
                "SomeIpArrayMinLength",
                "SomeIpArrayMaxLength",
                "SomeIpArrayLengthWidth")
        ]

        // Interface attributes
        for (fdInterface : fdInterfaces)
        {
            fdInterface.attributes.filter[isArray(it.target)].forEach[fd|
                validateArrayDeployment(fd,
                    "SomeIpAttrArrayMinLength",
                    "SomeIpAttrArrayMaxLength",
                    "SomeIpAttrArrayLengthWidth")
            ]
        }

        // Interface Function Arguments
        val fdArguments = new ArrayList<FDArgument>
        for (fdInterface : fdInterfaces)
        {
            // Interface method's input and output arguments
            fdInterface.methods.forEach[m|
                if (m.inArguments != null)
                    fdArguments.addAll(m.inArguments.arguments.filter[isArray(it.target)])
                if (m.outArguments != null)
                    fdArguments.addAll(m.outArguments.arguments.filter[isArray(it.target)])
            ]

            // Interface broadcast's output arguments
            fdInterface.broadcasts.forEach[bc|
                if (bc.outArguments != null)
                    fdArguments.addAll(bc.outArguments.arguments.filter[isArray(it.target)])
            ]
        }

        fdArguments.forEach[fd|
            validateArrayDeployment(fd,
                "SomeIpArgArrayMinLength",
                "SomeIpArgArrayMaxLength",
                "SomeIpArgArrayLengthWidth")
        ]

        validateCompoundMemberArrayDeployments
    }

    private def validateCompoundMemberArrayDeployments()
    {
        val fdCompounds = new ArrayList<FDElement>

        // Type collections
        for (typeCollection : fdTypeCollections)
            fdCompounds.addAll(typeCollection.types.filter(typeof(FDCompound)))

        // Interface local types
        for (fdInterface : fdInterfaces)
            fdCompounds.addAll(fdInterface.types.filter(typeof(FDCompound)))

        for (fdCompound : fdCompounds)
        {
            if (fdCompound instanceof FDStruct)
            {
                fdCompound.fields.forEach[
                    if (isArray(it.target))
                    {
                        validateArrayDeployment(it,
                            "SomeIpStructArrayMinLength",
                            "SomeIpStructArrayMaxLength",
                            "SomeIpStructArrayLengthWidth")
                    }
                ]
            }
            else if (fdCompound instanceof FDUnion)
            {
                fdCompound.fields.forEach[
                    if (isArray(it.target))
                    {
                        validateArrayDeployment(it,
                            "SomeIpUnionArrayMinLength",
                            "SomeIpUnionArrayMaxLength",
                            "SomeIpUnionArrayLengthWidth")
                    }
                ]
            }
        }
    }

    private def validateDeploymentProperties()
    {
        val fdTypeDeployments = new ArrayList<FDTypeDef>

        // Type collections
        for (typeCollection : fdTypeCollections)
            fdTypeDeployments.addAll(typeCollection.types)

        // Interface local types
        for (fdInterface : fdInterfaces)
            fdTypeDeployments.addAll(fdInterface.types)

        for (fdType : fdTypeDeployments)
        {
            if (fdType instanceof FDStruct)
            {
                fdType.fields.forEach[field|
                    if (!isArray(field.target))
                    {
                        field.properties.forEach[prop|
                            val propName = prop.decl.name
                            if (propName != null && propName.startsWith("SomeIpStructArray"))
                            {
                                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                    "Array deployment used for none array type '" + field.target.name + "'",
                                    prop, null, -1, null, null)
                                diagnostics.add(diag)
                            }
                        ]
                    }
                    else
                    {
                        field.properties.forEach[prop|
                            val propName = prop.decl.name
                            if (propName != null && propName.startsWith("SomeIpArray"))
                            {
                                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                    "Improper array deployment used for 'struct' field '" + field.target.name + "'. Use 'SomeIpStructArray' deployment properties instead.",
                                    prop, null, -1, null, null)
                                diagnostics.add(diag)
                            }
                        ]
                    }
                ]
            }
            else if (fdType instanceof FDUnion)
            {
                fdType.fields.forEach[field|
                    if (!isArray(field.target))
                    {
                        field.properties.forEach[prop|
                            val propName = prop.decl.name
                            if (propName != null && propName.startsWith("SomeIpUnionArray"))
                            {
                                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                    "Array deployment used for none array type '" + field.target.name + "'",
                                    prop, null, -1, null, null)
                                diagnostics.add(diag)
                            }
                        ]
                    }
                    else
                    {
                        field.properties.forEach[prop|
                            val propName = prop.decl.name
                            if (propName != null && propName.startsWith("SomeIpArray"))
                            {
                                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                    "Improper array deployment used for 'union' field '" + field.target.name + "'. Use 'SomeIpUnionArray' deployment properties instead.",
                                    prop, null, -1, null, null)
                                diagnostics.add(diag)
                            }
                        ]
                    }
                ]
            }
            else
            {
                if (!(fdType instanceof FDArray))
                {
                    fdType.properties.forEach[prop|
                        // This warning actually will never trigger, because the general Franca/FDepl validation
                        // already disallows to specify 'SomeIpArray' deployment properties for none array types.
                        // However, for safety reasons this warning is though checked here as well, in case
                        // this code is invoked without a prior general validation.
                        //
                        val propName = prop.decl.name
                        if (propName != null && propName.startsWith("SomeIpArray"))
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

        // Interface attributes
        for (fdInterface : fdInterfaces)
        {
            fdInterface.attributes.forEach[fdAttr|
                if (!isArray(fdAttr.target))
                {
                    fdAttr.properties.forEach[prop|
                        val propName = prop.decl.name
                        if (propName != null && propName.startsWith("SomeIpAttrArray"))
                        {
                            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                "Array deployment used for none array type '" + fdAttr.target.name + "'",
                                prop, null, -1, null, null)
                            diagnostics.add(diag)
                        }
                    ]
                }
                else
                {
                    fdAttr.properties.forEach[prop|
                        val propName = prop.decl.name
                        if (propName != null && propName.startsWith("SomeIpArray"))
                        {
                            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                "Improper array deployment used for attribute '" + fdAttr.target.name + "'. Use 'SomeIpAttrArray' deployment properties instead.",
                                prop, null, -1, null, null)
                            diagnostics.add(diag)
                        }
                    ]
                }
            ]
        }


        // Arguments
        val fdArguments = new ArrayList<FDArgument>
        for (fdInterface : fdInterfaces)
        {
            // Interface method's input and output arguments
            fdInterface.methods.forEach[m|
                if (m.inArguments != null)
                    fdArguments.addAll(m.inArguments.arguments.filter[it.target != null])
                if (m.outArguments != null)
                    fdArguments.addAll(m.outArguments.arguments.filter[it.target != null])
            ]

            // Interface broadcast's output arguments
            fdInterface.broadcasts.forEach[bc|
                if (bc.outArguments != null)
                    fdArguments.addAll(bc.outArguments.arguments.filter[it.target != null])
            ]
        }

        fdArguments.forEach[fdArg|
            fdArg.properties.forEach[prop|
                if (!isArray(fdArg.target))
                {
                    val propName = prop.decl.name
                    if (propName != null && propName.startsWith("SomeIpArgArray"))
                    {
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Array deployment used for none array type '" + fdArg.target.name + "'",
                            prop, null, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
                else
                {
                    val propName = prop.decl.name
                    if (propName != null && propName.startsWith("SomeIpArray"))
                    {
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Improper array deployment used for argument '" + fdArg.target.name + "'. Use 'SomeIpArgArray' deployment properties instead.",
                            prop, null, -1, null, null)
                        diagnostics.add(diag)
                    }
                }
            ]
        ]
    }

    private def isArray(FTypedElement elm)
    {
        if (elm == null)
            return false
        if (elm.array)
            return true
        if (elm.type != null)
        {
            if (elm.type.derived != null)
                return isArray(elm.type.derived)
        }
        return false
    }

    private def boolean isArray(FType typ)
    {
        if (typ instanceof FTypeRef)
            return isArray(typ.derived)
        if (typ instanceof FTypeDef)
        {
            if (typ.actualType != null)
                return isArray(typ.actualType.derived)
        }
        else
        {
            if (typ instanceof FArrayType)
                return true
        }
        return false
    }

    private def validateArrayDeployment(FDElement fdArray, String minLengthName, String maxLengthName, String lengthWidthName)
    {
        var propSomeIpArrayMinLength = fdArray.properties.findFirst[it.decl.name == minLengthName]
        var propSomeIpArrayMaxLength = fdArray.properties.findFirst[it.decl.name == maxLengthName]
        var propSomeIpArrayLengthWidth = fdArray.properties.findFirst[it.decl.name == lengthWidthName]

        var someIpArrayMinLength = getInteger(propSomeIpArrayMinLength)
        var someIpArrayMaxLength = getInteger(propSomeIpArrayMaxLength)
        var someIpArrayLengthWidth = getInteger(propSomeIpArrayLengthWidth)

        if (someIpArrayMinLength != null && someIpArrayMaxLength != null && someIpArrayMinLength == someIpArrayMaxLength && someIpArrayMinLength != 0)
        {
            // * If SomeIpArrayLengthWidth == 1, 2 or 4 bytes, SomeIpArrayMinLength and SomeIpArrayMaxLength are ignored.
            //
            if (someIpArrayLengthWidth == null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment with '" + minLengthName + "' = '" + maxLengthName + "' is missing a '" + lengthWidthName + " = 0' property.",
                    propSomeIpArrayMinLength, null, -1, null, null)
                diagnostics.add(diag)
            }
            else if (someIpArrayLengthWidth != 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment with '" + minLengthName + "' = '" + maxLengthName + "' does not specify '" + lengthWidthName + " = 0'.",
                    propSomeIpArrayLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
        else if (someIpArrayLengthWidth != null && someIpArrayLengthWidth == 0)
        {
            // * If SomeIpArrayLengthWidth == 0, the array has SomeIpArrayMaxLength elements.
            //
            if (someIpArrayMaxLength == null || someIpArrayMaxLength == 0)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment specifies a fixed length array type, but is missing a nonzero array length specification '" + maxLengthName + "'.",
                    propSomeIpArrayLengthWidth, null, -1, null, null)
                diagnostics.add(diag)
            }
            else if (someIpArrayMinLength != null && someIpArrayMaxLength != null && someIpArrayMinLength > someIpArrayMaxLength)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Array deployment contains a minimum array length '" + minLengthName + "' that exceeds the maximum array length '" + maxLengthName + ".",
                    propSomeIpArrayMinLength, null, -1, null, null)
                diagnostics.add(diag)
            }
        }


    }

    private def validateProviderInstanceDeployments()
    {
        fdInterfaceInstances.forEach[interfaceInstance|
            if (fdInterfaces.findFirst[target != null && interfaceInstance.target != null && target.equals(interfaceInstance.target)] == null)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "No deployment for interface \"" + getFullName(interfaceInstance.target) + "\".",
                    interfaceInstance, null, -1, null, null)
                diagnostics.add(diag)
            }
        ]
    }

    private def validateCompleteInterfaceDeployments(FDInterface fdInterface)
    {
        val FInterface fInterface = fdInterface.target
        if (fInterface != null)
        {
            fInterface.attributes.forEach[fAttr|
                if (fdInterface.attributes.findFirst[fdAttr|fAttr.equals(fdAttr.target)] == null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for attribute \"" + fAttr.name + "\".",
                        fAttr, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]

            fInterface.broadcasts.forEach[fBroadcast|
                if (fdInterface.broadcasts.findFirst[fdBroadcast|fBroadcast.equals(fdBroadcast.target)] == null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for broadcast \"" + fBroadcast.name + "\".",
                        fBroadcast, null, -1, null, null)
                    diagnostics.add(diag)
                }
            ]

            fInterface.methods.forEach[fMethod|
                if (fdInterface.methods.findFirst[fdMethod|fMethod.equals(fdMethod.target)] == null)
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "No deployment for method \"" + fMethod.name + "\".",
                        fMethod, null, -1, null, null)
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
            if (fdInterface.target != null && fdInterface.target != null && fdInterface.target == fInterface)
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
        if (fdInterface.target != null)
        {
            val fBaseInterface = fdInterface.target.base
            if (fBaseInterface != null)
            {
                val fdBaseInterface = getDeploymentForInterface(fBaseInterface, fdInterface)
                if (fdBaseInterface != null)
                {
                    val baseInterfaceIdProps = allInterfaceIdProps.get(fdBaseInterface)
                    if (baseInterfaceIdProps != null)
                    {
                        for (idProps : baseInterfaceIdProps.entrySet)
                        {
                            var props = interfaceIdProps.get(idProps.key)
                            if (props == null)
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
        if (fdInterface.target != null)
        {
            val fBaseInterface = fdInterface.target.base
            if (fBaseInterface != null)
            {
                val fdBaseInterface = getDeploymentForInterface(fBaseInterface, fdInterface)
                if (fdBaseInterface != null)
                {
                    val baseInterfaceIdEventGroups = allInterfaceIdEventGroups.get(fdBaseInterface)
                    if (baseInterfaceIdEventGroups != null)
                    {
                        for (idEventGroups : baseInterfaceIdEventGroups.entrySet)
                        {
                            var eventGroups = interfaceIdEventGroups.get(idEventGroups.key)
                            if (eventGroups == null)
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
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
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
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
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
            if (props != null && props.size > 1)
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
     *   specified within the 'SomeIpEventGroups' setting.
     */
    private def validateInterfaceAttributes(
        FDInterface fdInterface,
        HashMap<Integer, ArrayList<FDProperty>> methodIds,
        HashMap<Integer, ArrayList<FDProperty>> eventIds,
        HashMap<Integer, ArrayList<FDValue>> eventGroupIds)
    {
        for (attribute : fdInterface.attributes)
        {
            val propSomeIpGetterID = attribute.properties.findFirst[it.decl.name == "SomeIpGetterID"]
            val propSomeIpSetterID = attribute.properties.findFirst[it.decl.name == "SomeIpSetterID"]
            val propSomeIpNotifierID = attribute.properties.findFirst[it.decl.name == "SomeIpNotifierID"]

            val getterId = getId(propSomeIpGetterID)
            val setterId = getId(propSomeIpSetterID)
            val notifierId = getId(propSomeIpNotifierID)

            var validGetterId = false
            var validSetterId = false
            var validNotifierId = false

            if (getterId != null)
            {
                // 'SomeIpGetterID = 0' is allowed!
                if (getterId >= 0)
                    validGetterId = true
            }

            if (setterId != null)
            {
                // 'SomeIpSetterID = 0' is allowed if the attribute is marked as readonly
                if (setterId > 0 || (setterId == 0 && attribute.target.isReadonly))
                    validSetterId = true
            }

            if (notifierId != null)
            {
                // 'SomeIpNotifierID = 0' is allowed if the attribute is marked as noSubscriptions
                if (notifierId > 0 || (notifierId == 0 && attribute.target.isNoSubscriptions))
                    validNotifierId = true
            }

            // It isn't valid to specify 'SomeIpGetterID = 0' + 'SomeIpSetterID = 0' + 'SomeIpNotifierID = 0'
            if (((setterId != null && setterId == 0) &&
                (getterId != null && getterId == 0) &&
                (notifierId != null && notifierId == 0))) {
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
                var diag = new FeatureBasedDiagnostic(
                    Diagnostic.WARNING,
                    "Attribute \"" + getAttributeName(attribute) + "\" has no valid 'SomeIpGetterID', 'SomeIpSetterID' or 'SomeIpNotifierID' specified.",
                    attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                diagnostics.add(diag)
            }
            else
            {
                // If there is no 'SomeIpSetterID' specified, check whether the respective attribute is declared as 'readonly'
                //
                if (!validSetterId)
                {
                    if (!attribute.target.readonly)
                    {
                        var attrName = getAttributeName(attribute)
                        var diag = new FeatureBasedDiagnostic(
                            Diagnostic.WARNING,
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
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + attrName + "\" has a 'SomeIpSetterID' specified, but the associated attribute in the interface definition is declared as 'readonly'.",
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
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
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
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + attrName + "\" has a 'SomeIpNotifierID' specified, but the associated attribute in the interface definition is declared as 'noSubscriptions'.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // If there is a 'SomeIpNotifierID' specified, check whether there is also a valid event group specified.
                //
                if (validNotifierId)
                {
                    var validEventGroup = false
                    var propEventGroups = attribute.properties.findFirst[it.decl.name == "SomeIpEventGroups"]
                    if (propEventGroups != null)
                    {
                        for (fdEventGroup : propEventGroups.value.array.values)
                        {
                            if (fdEventGroup instanceof FDInteger)
                            {
                                var eventGroupId = fdEventGroup.value
                                if (eventGroupId >= 1)
                                {
                                    var props = eventGroupIds.get(eventGroupId)
                                    if (props == null) {
                                        props = new ArrayList<FDValue>
                                        eventGroupIds.put(eventGroupId, props)
                                    }
                                    props.add(fdEventGroup)
                                    validEventGroup = true
                                }
                                else
                                {

                                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                        "Attribute \"" + getAttributeName(attribute) + "\" contains an invalid event group of " + eventGroupId + ".",
                                        fdEventGroup, null, -1, null, null)
                                    diagnostics.add(diag)
                                }
                            }
                        }
                    }
                    if (!validEventGroup)
                    {
                        var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                            "Attribute \"" + getAttributeName(attribute) + "\" has no valid 'SomeIpEventGroups' specified.",
                            attribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                        diagnostics.add(diag)
                    }
                }

                // Duplicate 'SomeIpGetterId = 0' are valid and Ok.
                if (validGetterId && getterId > 0)
                {
                    var id = (propSomeIpGetterID.value.single as FDInteger).value
                    var props = methodIds.get(id)
                    if (props == null) {
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
                    if (props == null) {
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
                    if (props == null) {
                        props = new ArrayList<FDProperty>
                        eventIds.put(id, props)
                    }
                    props.add(propSomeIpNotifierID)
                }
            }
        }
    }

    /**
     * - Every method must have a 'SomeIpMethodID [1..32767]' specified.
     */
    private def validateInterfaceMethods(FDInterface fdInterface, HashMap<Integer, ArrayList<FDProperty>> methodIds)
    {
        val MIN_ID_VALUE = 1
        val MAX_ID_VALUE = 32767
        for (FDMethod fdMethod : fdInterface.methods)
        {
            var propMethodId = fdMethod.properties.findFirst[it.decl.name == "SomeIpMethodID"]
            if (isValidId(propMethodId))
            {
                var methodId = (propMethodId.value.single as FDInteger).value
                if (methodId >= MIN_ID_VALUE && methodId <= MAX_ID_VALUE)
                {
                    var props = methodIds.get(methodId)
                    if (props == null) {
                        props = new ArrayList<FDProperty>
                        methodIds.put(methodId, props)
                    }
                    props.add(propMethodId)
                }
                else
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Method ID for \"" + getMethodName(fdMethod) + "\" is not within range " + MIN_ID_VALUE + " - " + MAX_ID_VALUE + ".",
                        fdMethod, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
            else
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Method ID for \"" + getMethodName(fdMethod) + "\" is not valid. Specify a value within range " + MIN_ID_VALUE + " - " + MAX_ID_VALUE + ".",
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
        val MIN_ID_VALUE = 32769
        val MAX_ID_VALUE = 65534
        for (FDBroadcast fdBroadcast : fdInterface.broadcasts)
        {
            // Every broadcast must have a 'SomeIpEventID [32769..65534]' specified.
            //
            var propEventId = fdBroadcast.properties.findFirst[it.decl.name == "SomeIpEventID"]
            if (isValidId(propEventId))
            {
                var eventId = (propEventId.value.single as FDInteger).value
                if (eventId >= MIN_ID_VALUE && eventId <= MAX_ID_VALUE)
                {
                    var props = eventIds.get(eventId)
                    if (props == null) {
                        props = new ArrayList<FDProperty>
                        eventIds.put(eventId, props)
                    }
                    props.add(propEventId)
                }
                else
                {
                    var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                        "Event ID for broadcast \"" + getBroadcastName(fdBroadcast) + "\" is not within range " + MIN_ID_VALUE + " - " + MAX_ID_VALUE + ".",
                        fdBroadcast, null, -1, null, null)
                    diagnostics.add(diag)
                }
            }
            else
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Event ID for broadcast \"" + getBroadcastName(fdBroadcast) + "\" is not valid. Specify a value within range " + MIN_ID_VALUE + " - " + MAX_ID_VALUE + ".",
                    fdBroadcast, null, -1, null, null)
                diagnostics.add(diag)
            }

            // Every broadcast must have a valid event group specified within the 'SomeIpEventGroups' setting.
            //
            var validEventGroup = false
            var propEventGroups = fdBroadcast.properties.findFirst[it.decl.name == "SomeIpEventGroups"]
            if (propEventGroups != null)
            {
                for (fdEventGroup : propEventGroups.value.array.values)
                {
                    if (fdEventGroup instanceof FDInteger)
                    {
                        var eventGroupId = fdEventGroup.value
                        if (eventGroupId >= 1)
                        {
                            var props = eventGroupIds.get(eventGroupId)
                            if (props == null) {
                                props = new ArrayList<FDValue>
                                eventGroupIds.put(eventGroupId, props)
                            }
                            props.add(fdEventGroup)
                            validEventGroup = true

                            // Save the event group IDs of 'selective' broadcasts.
                            if (fdBroadcast.target.isSelective)
                            {
                                props = selectiveBroadcastEventGroupIds.get(eventGroupId)
                                if (props == null) {
                                    props = new ArrayList<FDValue>
                                    selectiveBroadcastEventGroupIds.put(eventGroupId, props)
                                }
                                props.add(fdEventGroup)
                            }
                        }
                        else
                        {
                            var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                                "Broadcast \"" + getBroadcastName(fdBroadcast) + "\" contains an invalid event group of " + eventGroupId + ".",
                                fdEventGroup, null, -1, null, null)
                            diagnostics.add(diag)
                        }
                    }
                }
            }
            if (!validEventGroup)
            {
                var diag = new FeatureBasedDiagnostic(Diagnostic.WARNING,
                    "Broadcast \"" + getBroadcastName(fdBroadcast) + "\" has no valid event group specified.",
                    fdBroadcast, null, -1, null, null)
                diagnostics.add(diag)
            }
        }
    }

    private def getInterfaceName(FDInterface fdInterface)
    {
        if (fdInterface == null || fdInterface.target == null)
            return null
        return fdInterface.target.name
    }

    private def getAttributeName(FDAttribute attribute)
    {
        if (attribute == null || attribute.target == null)
            return null
        return attribute.target.name
    }

    private def getMethodName(FDMethod method)
    {
        if (method == null || method.target == null)
            return null
        return method.target.name
    }

    private def getBroadcastName(FDBroadcast broadcast)
    {
        if (broadcast == null || broadcast.target == null)
            return null
        return broadcast.target.name
    }

    private def isValidId(FDProperty prop)
    {
        if (prop == null || prop.value == null)
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
        if (prop == null || prop.value == null)
            return null
        if (!(prop.value.single instanceof FDInteger))
            return null
        return (prop.value.single as FDInteger).value
    }

    private def String getFullName(FInterface intf)
    {
        if (intf == null)
            return ""
        return (intf.eContainer as FModel).name + "." + intf.name
    }

    private def validateImports(Collection<FDModel> fdepls)
    {
        fdepls.forEach[it.checkMissingDeploymentImports]
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
            if (fdModel.deployments.findFirst[(it instanceof FDInterface) || (it instanceof FDTypes)] == null)
                return
        }

        var fdeplUris = getImportedFDepls(fdModel, recursive)
        var fidlUris = getImportedFidls(fdModel, recursive)

        for (fidl : fidlUris)
        {
            val correspondingFdeplImportSpec = fidl.toString.replaceFidlWithFDeplExtension

            // skip the FIDL which corresponds to the FDEPL which we are validating right now
            if (!fdModel.eResource.URI.toString.equals(correspondingFdeplImportSpec))
            {
                if (fdeplUris.findFirst[it.toString.equals(correspondingFdeplImportSpec)] == null)
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

    private def Collection<URI> getImportedFDepls(FDModel fdModel, boolean recursive)
    {
        val uris = new ArrayList<URI>
        for (import : fdModel.imports)
        {
            // Process only FDEPL files
            if (import.importURI.endsWith(FDEPL_FILE_EXTENSION_SUFFIX))
            {
                // Skip Deployment Specification files
                if (!import.importURI.endsWith(DEPLOYMENT_SPECIFICATION_FILENAME_SUFFIX))
                {
                    var importUri = getAbsoluteUri(fdModel, import.importURI)
                    if (!uris.contains(importUri))
                    {
                        var fdImportedModel = getFDModel(importUri)
                        if (fdImportedModel != null)
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

    private def Collection<URI> getImportedFidls(FDModel fdModel, boolean recursive)
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
                    if (fImportedModel != null)
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
                    if (fImportedModel != null)
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
        var String displayPath = null;
        if (uri.isPlatformResource())
            displayPath = uri.toPlatformString(true);
        if (displayPath == null)
            displayPath = uri.toFileString();
        if (displayPath == null)
            displayPath = uri.toString();
        return displayPath;
    }
}
