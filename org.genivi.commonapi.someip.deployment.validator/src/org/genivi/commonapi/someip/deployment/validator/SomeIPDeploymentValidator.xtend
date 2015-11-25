package org.genivi.commonapi.someip.deployment.validator

import java.util.Collection
import org.eclipse.emf.common.util.DiagnosticChain
import org.franca.deploymodel.dsl.fDeploy.FDAttribute
import org.franca.deploymodel.dsl.fDeploy.FDInteger
import org.franca.deploymodel.dsl.fDeploy.FDInterface
import org.franca.deploymodel.dsl.fDeploy.FDModel
import org.franca.deploymodel.dsl.fDeploy.FDProperty
import org.franca.deploymodel.dsl.fDeploy.FDComplexValue
import org.eclipse.xtext.validation.FeatureBasedDiagnostic
import org.eclipse.emf.common.util.Diagnostic
import static org.franca.deploymodel.dsl.fDeploy.FDeployPackage$Literals.*

class SomeIPDeploymentValidator
{
    var DiagnosticChain diagnostics

    def boolean validate(Collection<FDModel> fdepls, DiagnosticChain diagnostics)
    {
        this.diagnostics = diagnostics

        var hasValidationError = false
        for (fdepl : fdepls)
        {
            var deplInterfaces = fdepl.deployments.filter(typeof(FDInterface))
            for (deplInterface : deplInterfaces)
            {
                for (attribute : deplInterface.attributes)
                    validateAttribute(deplInterface, attribute)
            }
        }
        return !hasValidationError
    }

    def validateAttribute(FDInterface deplInterface, FDAttribute deplAttribute)
    {
        // The SomeIP deployment needs to have at least one of the following properties specified
        //
        var propSomeIpGetterID = deplAttribute.properties.findFirst[it.decl.name == "SomeIpGetterID"]
        var propSomeIpSetterID = deplAttribute.properties.findFirst[it.decl.name == "SomeIpSetterID"]
        var propSomeIpNotifierID = deplAttribute.properties.findFirst[it.decl.name == "SomeIpNotifierID"]
        if (!isValidId(propSomeIpGetterID) && !isValidId(propSomeIpSetterID) && !isValidId(propSomeIpNotifierID))
        {
            var intfName = getInterfaceName(deplInterface)
            var attrName = getAttributeName(deplAttribute)
            var diag = new FeatureBasedDiagnostic(
                Diagnostic.ERROR,
                "Some/IP deployment for attribute \"" + attrName + "\" in interface \"" + intfName + "\" has no valid 'SomeIpGetterID', 'SomeIpSetterID' or 'SomeIpNotifierID' specified.",
                deplAttribute, FD_ATTRIBUTE__TARGET, -1, null, null);
            diagnostics.add(diag)
        }
        else
        {
            // If there is no 'SomeIpSetterID' specified, check whether the respective attribute is declared as 'readonly'
            //
            if (!isValidId(propSomeIpSetterID))
            {
                if (!deplAttribute.target.readonly)
                {
                    var intfName = getInterfaceName(deplInterface)
                    var attrName = getAttributeName(deplAttribute)
                    var diag = new FeatureBasedDiagnostic(
                        Diagnostic.ERROR,
                        "Some/IP deployment for attribute \"" + attrName + "\" in interface \"" + intfName + "\" has no valid 'SomeIpSetterID' specified, but the associated attribute in the interface definition is not declared as 'readonly'.",
                        deplAttribute, FD_ATTRIBUTE__TARGET, -1, null, null
                    );
                    diagnostics.add(diag)
                }
            }

            // If there is no 'SomeIpNotifierID' specified, check whether the associated attribute is declared as 'noSubscriptions'
            //
            if (!isValidId(propSomeIpNotifierID))
            {
                if (!deplAttribute.target.noSubscriptions)
                {
                    var intfName = getInterfaceName(deplInterface)
                    var attrName = getAttributeName(deplAttribute)
                    var diag = new FeatureBasedDiagnostic(Diagnostic.ERROR,
                        "Some/IP deployment for attribute \"" + attrName + "\" in interface \"" + intfName + "\" has no valid 'SomeIpNotifierID' specified, but the associated attribute in the interface definition is not declared as 'noSubscriptions'.",
                        deplAttribute, FD_ATTRIBUTE__TARGET, -1, null, null)
                    diagnostics.add(diag)
                }
            }
        }
    }

    def getAttributeName(FDAttribute attribute)
    {
        if (attribute == null || attribute.target == null)
            return null
        return attribute.target.name
    }

    def isValidId(FDProperty prop)
    {
        if (prop == null)
            return false
        if (!(prop.value instanceof FDComplexValue))
            return false
        var propValue = prop.value as FDComplexValue
        if (!(propValue.single instanceof FDInteger))
            return false
        if ((propValue.single as FDInteger).value <= 0)
            return false
        return true
    }

    def getInterfaceName(FDInterface fdIntf)
    {
        if (fdIntf != null)
        {
            if (fdIntf.target != null)
                return fdIntf.target.name
            return fdIntf.name
        }
        return null
    }
}
