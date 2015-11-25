package org.genivi.commonapi.someip.cli;

import java.util.List;

import org.eclipse.emf.common.util.BasicDiagnostic;
import org.eclipse.emf.common.util.Diagnostic;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.franca.deploymodel.dsl.fDeploy.FDModel;
import org.genivi.commonapi.core.verification.CommandlineValidator;
import org.genivi.commonapi.someip.deployment.validator.SomeIPDeploymentValidator;

public class CommandLineValidatorSomeIp extends CommandlineValidator
{
    public CommandLineValidatorSomeIp(ValidationMessageAcceptor cliMessageAcceptor)
    {
        super(cliMessageAcceptor);
    }

    @Override
    protected List<Diagnostic> validateDeployment(List<FDModel> fdepls)
    {
        BasicDiagnostic diagnostics = new BasicDiagnostic();
        SomeIPDeploymentValidator validator = new SomeIPDeploymentValidator();
        validator.validate(fdepls, diagnostics);
        return diagnostics.getChildren();
    }
}
