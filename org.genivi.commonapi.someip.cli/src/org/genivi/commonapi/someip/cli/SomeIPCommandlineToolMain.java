/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.cli;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import org.eclipse.core.runtime.Platform;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.eclipse.xtext.validation.AbstractValidationMessageAcceptor;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.franca.core.dsl.FrancaIDLRuntimeModule;
import org.franca.deploymodel.dsl.fDeploy.FDModel;
import org.genivi.commonapi.console.CommandlineTool;
import org.genivi.commonapi.console.ConsoleLogger;
import org.genivi.commonapi.core.generator.GeneratorFileSystemAccess;
import org.genivi.commonapi.core.verification.CommandlineValidator;
import org.genivi.commonapi.someip.generator.FrancaSomeIPGenerator;
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;

import com.google.inject.Guice;
import com.google.inject.Injector;

/**
 * Receive command line arguments and set them as preference values for the code generation.
 */
public class SomeIPCommandlineToolMain extends CommandlineTool {

	protected FPreferencesSomeIP someIpPref;
	protected GeneratorFileSystemAccess fsa;
	protected Injector injector;
	protected IGenerator francaGenerator;
	protected String scope = "SomeIP validation: ";

	private ValidationMessageAcceptor cliMessageAcceptor = new AbstractValidationMessageAcceptor() {

		@Override
		public void acceptInfo(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
			ConsoleLogger.printLog(scope + message);
		}

		@Override
		public void acceptWarning(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
		    hasValidationWarning = true;
			ConsoleLogger.printLog("Warning: " + scope + message);
		}

		@Override
		public void acceptError(String message, EObject object,
				EStructuralFeature feature, int index, String code,
				String... issueData) {
			hasValidationError = true;
			ConsoleLogger.printErrorLog("Error: " + scope + message);
		}
	};
	/**
	 * The constructor registers the needed bindings to use the generator
	 */
	public SomeIPCommandlineToolMain() {

		injector = Guice.createInjector(new FrancaIDLRuntimeModule());

		fsa = injector.getInstance(GeneratorFileSystemAccess.class);

		someIpPref = FPreferencesSomeIP.getInstance();
	}

	protected String normalize(String _path) {
		File itsFile = new File(_path);
		return itsFile.getAbsolutePath();
	}

	public int generateSomeIp(List<String> fileList) {
		francaGenerator = injector.getInstance(FrancaSomeIPGenerator.class);

		return doGenerate(fileList);
	}

	/**
	 * Call the franca generator for the specified list of files.
	 *
	 * @param fileList
	 *            the list of files to generate code from
	 */
	protected int doGenerate(List<String> _fileList) {
		fsa.setOutputConfigurations(FPreferencesSomeIP.getInstance()
				.getOutputpathConfiguration());

		XtextResourceSet rsset = injector.getProvider(XtextResourceSet.class)
				.get();

		ConsoleLogger.printLog("Using Franca Version " + getFrancaVersion());
		int error_state = NO_ERROR_STATE;

		// Create absolute paths
		List<String> fileList = new ArrayList<String>();
		for (String path : _fileList) {
			String absolutePath = normalize(path);
			fileList.add(absolutePath);
		}

		for (String file : fileList) {
			if (file.endsWith(FDEPL_EXTENSION)) {
				URI uri = URI.createFileURI(file);
				Resource resource = null;
				try {
					resource = rsset.createResource(uri);
				} catch (IllegalStateException ise) {
					ConsoleLogger
							.printErrorLog("Failed to create a resource from "
									+ file + "\n" + ise.getMessage());
					error_state = ERROR_STATE;
					continue;
				}
				hasValidationError = false;
				if (isValidation) {
					validateSomeIP(resource);
				}

				if (hasValidationError) {
					ConsoleLogger.printErrorLog(file
							+ " contains validation errors !");
					error_state = ERROR_STATE;
				}
				else if (hasValidationWarning && isValidationWarningsAsErrors) {
				    cliMessageAcceptor.acceptError("Warnings are treated as errors - validation failed", null, null, 0, null, (String[])null);
                    ConsoleLogger.printErrorLog(file
                            + " contains validation warnings !");
                    error_state = ERROR_STATE;
				} else if (isCodeGeneration) {
					ConsoleLogger.printLog("Generating code for " + file);
					try {
						if (FPreferencesSomeIP.getInstance().getPreference(
								PreferenceConstantsSomeIP.P_OUTPUT_SUBDIRS_SOMEIP, "false").equals("true")) {
							String subdir = (new File(file)).getName();
							subdir = subdir.replace(".fidl", "");
							subdir = subdir.replace(".fdepl", "");
							fsa.setOutputConfigurations(FPreferencesSomeIP.getInstance()
								.getOutputpathConfiguration(subdir));
							}
						francaGenerator.doGenerate(resource, fsa);
					} catch (Exception e) {
						System.err.println("Failed to generate code for "
								+ file + " due to " + e.getMessage());
						error_state = ERROR_STATE;
					}
				}
				if(resource != null) {
					// Clear each resource from the resource set in order to let other fidl files import it.
					// Otherwise an IllegalStateException will be thrown for a resource that was already created.
					resource.unload();
					rsset.getResources().clear();
				}
			} else {
				ConsoleLogger
						.printLog("Cannot generate code for the following file, because it does not have the "
								+ FDEPL_EXTENSION + " extension: \n    " + file);
				error_state = ERROR_STATE;
			}
		}
		if (dumpGeneratedFiles) {
			fsa.dumpGeneratedFiles();
		}
		fsa.clearFileList();
		dumpGeneratedFiles = false;
		return error_state;
	}

	/**
	 * Validate the resource (fdepl file)
	 *
	 * @param resource
	 * @return false if an error occurred else true.
	 */
	private void validateSomeIP(Resource resource) {
		EObject model = null;
		CommandlineValidator cliValidator = new CommandLineValidatorSomeIp(
				cliMessageAcceptor);

		cliValidator.addIgnoreString("Imported resource could not be found");

		//ConsoleLogger.printLog("validating " + resource.getURI().lastSegment());

		model = cliValidator.loadResource(resource);

		if (model != null) {
			if (model instanceof FDModel) {
	            // check existence of imported fidl/fdepl files
				cliValidator.validateImports((FDModel) model, resource.getURI());

				// perform Some/IP specific deployment validation
				cliValidator.validateDeployment(resource.getURI());
			}
		}
	}

	/**
	 * Set the text from a file which will be inserted as a comment in each generated file (for example your license)
	 * @param fileWithText
	 * @return
	 */
	public void setLicenseText(String fileWithText) {

		String licenseText = getLicenseText(fileWithText);

		if (licenseText != null && !licenseText.isEmpty())
		{
			someIpPref.setPreference(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, licenseText);
		}
	}

	@Override
    public String getFrancaVersion() {
		return Platform.getBundle("org.franca.core").getVersion().toString();
	}

	public void setNoProxyCode() {
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, "false");
		ConsoleLogger.printLog("No proxy code will be generated");
	}

	public void setNoStubCode() {
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, "false");
		ConsoleLogger.printLog("No stub code will be generated");
	}

	public void setNoCommonCode() {
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_GENERATE_COMMON_SOMEIP,
				"false");
		ConsoleLogger.printLog("No common code will be generated");
	}

	public void setDefaultDirectory(String optionValue) {
		ConsoleLogger.printLog("Default output directory: " + optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_DEFAULT_SOMEIP, optionValue);
		// In the case where no other output directories are set,
		// this default directory will be used for them
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, optionValue);
	}

	public void setDestinationSubdirs() {
		ConsoleLogger.printLog("Using destination subdirs");
		someIpPref.setPreference(
			PreferenceConstantsSomeIP.P_OUTPUT_SUBDIRS_SOMEIP, "true");
	}

	public void setCommonDirectory(String optionValue) {
		ConsoleLogger.printLog("Common output directory: " + optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, optionValue);
	}

	public void setProxyDirectory(String optionValue) {
		ConsoleLogger.printLog("Proxy output directory: " + optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, optionValue);
	}

	public void setStubDirectory(String optionValue) {
		ConsoleLogger.printLog("Stub output directory: " + optionValue);
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, optionValue);
	}

	public void setLogLevel(String optionValue) {
		if (PreferenceConstantsSomeIP.LOGLEVEL_QUIET.equals(optionValue)) {
			someIpPref.setPreference(
					PreferenceConstantsSomeIP.P_LOGOUTPUT_SOMEIP, "false");
			ConsoleLogger.enableLogging(false);
			ConsoleLogger.enableErrorLogging(false);
		}
		if (PreferenceConstantsSomeIP.LOGLEVEL_VERBOSE.equals(optionValue)) {
			someIpPref.setPreference(
					PreferenceConstantsSomeIP.P_LOGOUTPUT_SOMEIP, "true");
			ConsoleLogger.enableErrorLogging(true);
			ConsoleLogger.enableLogging(true);
		}
	}

	public void disableValidation() {
		ConsoleLogger.printLog("Validation is off");
		isValidation = false;
	}

	public void enableValidationWarningsAsErrors() {
	    isValidationWarningsAsErrors = true;
	}

	/**
	 * set a preference value to disable code generation
	 */
	public void disableCodeGeneration() {
		ConsoleLogger.printLog("Code generation is off");
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_GENERATE_CODE_SOMEIP, "false");
	}

	/**
	 * Set a preference value to disable code generation for included types and
	 * interfaces
	 */
	public void noCodeforDependencies() {
		ConsoleLogger.printLog("Code generation for dependencies is off");
		someIpPref.setPreference(
				PreferenceConstantsSomeIP.P_GENERATE_DEPENDENCIES_SOMEIP, "false");
	}

	public void listGeneratedFiles() {
		dumpGeneratedFiles = true;
	}

	public void disableSyncCalls() {
		ConsoleLogger.printLog("Code generation for synchronous calls is off");
		someIpPref
				.setPreference(
						PreferenceConstantsSomeIP.P_GENERATE_SYNC_CALLS_SOMEIP,
						"false");
	}
}
