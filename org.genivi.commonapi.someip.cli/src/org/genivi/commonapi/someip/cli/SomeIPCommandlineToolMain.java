/*
 * Copyright (C) 2013 BMW Group Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de) This Source Code Form is
 * subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the
 * MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

package org.genivi.commonapi.someip.cli;

import java.io.BufferedReader;
import java.io.File;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

import org.eclipse.core.runtime.Platform;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.xtext.generator.IGenerator;
import org.eclipse.xtext.generator.JavaIoFileSystemAccess;
import org.eclipse.xtext.resource.XtextResourceSet;
import org.franca.core.dsl.FrancaIDLRuntimeModule;
import org.genivi.commonapi.console.ConsoleLogger;
import org.genivi.commonapi.someip.generator.FrancaSomeIPGenerator;
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;

import com.google.inject.Guice;
import com.google.inject.Injector;

/**
 * Receive command line arguments and set them as preference values for the code generation.
 */
public class SomeIPCommandlineToolMain {

	public static final String                      FILESEPARATOR    = System.getProperty("file.separator");
	public static final String                      FILESEPARATORIMP = "/";
	
    public static final String                      TEMP_PFAD         = System.getProperty("user.dir") + FILESEPARATOR + "temp";
    public static final String                      SOMEIP_DEPL       = TEMP_PFAD + FILESEPARATOR + "org.genivi.commonapi.someip"
                                                                              + FILESEPARATOR + "deployment" + FILESEPARATOR
                                                                              + "CommonAPI-SomeIP_deployment.fdepl";
    public static final String                      SOMEIP_PFAD       = TEMP_PFAD + FILESEPARATOR + "org.genivi.commonapi.someip"
                                                                              + FILESEPARATOR + "deployment";
    public static final String                      TEMP_FDEPL_PFAD   = TEMP_PFAD + FILESEPARATOR + "fdepl";	

	public static final String                      CORE_DEPL        = TEMP_PFAD + FILESEPARATOR + "org.genivi.commonapi.core"
																			+ FILESEPARATOR + "deployment" + FILESEPARATOR
																			+ "CommonAPI_deployment.fdepl";
	public static final String                      CORE_PFAD        = TEMP_PFAD + FILESEPARATOR + "org.genivi.commonapi.core"
																			+ FILESEPARATOR + "deployment";
	public static final String                      FDEPL_EXTENSION = ".fdepl";

	// All given files were saved in this list with an absolute path
	protected static Set<String>                     filelist         = new LinkedHashSet<String>();
	// true if for all interfaces have to be generated the stubs
	protected static boolean                          allstubs         = false;

	protected FPreferencesSomeIP   	someIpPref;
	protected JavaIoFileSystemAccess fsa;
	protected Injector injector;
	protected IGenerator francaGenerator;
	public static final int ERROR_STATE = 1;
	public static final int NO_ERROR_STATE = 0;
	
	/**
	 * The constructor registers the needed bindings to use the generator 
	 */
	public SomeIPCommandlineToolMain() {

		injector = Guice.createInjector(new FrancaIDLRuntimeModule());

		fsa = injector.getInstance(JavaIoFileSystemAccess.class);

		someIpPref = FPreferencesSomeIP.getInstance();
	}    



	public void generateSomeIp(List<String> fileList)
	{
		francaGenerator = injector.getInstance(FrancaSomeIPGenerator.class);		

		doGenerate(fileList);
	}	    

	/**
	 * Call the franca generator for the specified list of files.
	 * @param fileList the list of files to generate code from
	 */
	protected void doGenerate(List<String> fileList)
	{
		fsa.setOutputConfigurations(FPreferencesSomeIP.getInstance().getOutputpathConfiguration());

		XtextResourceSet rsset = injector.getProvider(XtextResourceSet.class).get();	

		ArrayList<String> filelist = new ArrayList<String>();

		/*
		 * Reading the options and the files given in the arguments and they
		 * will be saved in the predefined attributes
		 */
		String francaversion = getFrancaVersion();
		for (String element : fileList)
		{
			File file = new File(createAbsolutPath(element));
			if (!file.exists() || file.isDirectory())
			{
				ConsoleLogger.printErrorLog("The following path won't be generated because it doesn't exists:\n" + element + "\n");
			}
			else
				filelist.add(createAbsolutPath(element));
		}
		if (filelist.size() == 0)
		{
			ConsoleLogger.printErrorLog("There are no valid files to generate!");
			return;
		}
		ConsoleLogger.printLog("Using Franca Version " + francaversion);

		int error_state = NO_ERROR_STATE;
		for(String file : filelist) {
			if(file.endsWith(FDEPL_EXTENSION)) {
				URI uri = URI.createFileURI(file);
				Resource resource = rsset.createResource(uri);
				if(validate(resource)) {
					ConsoleLogger.printLog("Generating code for " + file);
					try {
						francaGenerator.doGenerate(resource, fsa);
					}
					catch (Exception e) {
						ConsoleLogger.printErrorLog("Failed to generate code: " + e.getMessage());
						error_state = ERROR_STATE;
					}	
				}
				else {
					ConsoleLogger.printErrorLog(file + " contains validation errors !");
					error_state = ERROR_STATE;
				}
			} 
			else {
				ConsoleLogger.printLog("Cannot generate code for the following file, because it does not have the " + FDEPL_EXTENSION + " extension: \n    " + file);
				error_state = ERROR_STATE;
			}
		}
		System.exit(error_state);
	}

	private boolean validate(Resource resource) {
		if(resource != null && resource.getURI().isFile())   {
			try {
				resource.load(Collections.EMPTY_MAP);
			} catch (IOException e) {
				e.printStackTrace();
			}
			ConsoleLogger.printLog("validating...");
			// check for (internal )resource validation errors
			for(org.eclipse.emf.ecore.resource.Resource.Diagnostic error : resource.getErrors()) {
				ConsoleLogger.printErrorLog("ERROR at line: " + error.getLine() + " : " + error.getMessage());
				return false;
			}
		}
		return true;
	}	
	
	

	/**
	 * Set the text from a file which will be inserted as a comment in each generated file (for example your license)
	 * 
	 * @param fileWithText
	 * @return
	 */
	public void setLicenseText(String fileWithText)
	{
		if (fileWithText != null && !fileWithText.isEmpty())
		{
			File file = new File(createAbsolutPath(fileWithText));
			if (!file.exists() || file.isDirectory())
			{
				ConsoleLogger.printErrorLog("Please write a path to an existing file after -p");
			}
			BufferedReader inReader = null;
			String licenseText = "";
			try
			{
				inReader = new BufferedReader(new FileReader(file));
				String thisLine;
				while ((thisLine = inReader.readLine()) != null)
				{
					licenseText = licenseText + thisLine + "\n";
				}
				if (licenseText != null && !licenseText.isEmpty())
				{
					someIpPref.setPreference(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, licenseText);
				}
			}
			catch (IOException e)
			{
				ConsoleLogger.printLog("Failed to set the text from the given file: " + e.getLocalizedMessage());
			}
			finally
			{
				try
				{
					inReader.close();
				}
				catch (Exception e)
				{
					;
				}
			}
			ConsoleLogger.printLog("The following text was set as header: \n" + licenseText);
		}
		else
		{
			ConsoleLogger.printErrorLog("Please write a path to an existing file after -p");
		}
	} 

	/**
	 * creates a absolute path from a relative path which starts on the current
	 * user directory
	 * 
	 * @param path
	 *            the relative path which start on the current user-directory
	 * @return the created absolute path
	 */
	public String createAbsolutPath(String path)
	{
		return createAbsolutPath(path, System.getProperty("user.dir") + FILESEPARATOR);
	}

	/**
	 * Here we create an absolute path from a relativ path and a rootpath from
	 * which the relative path begins
	 * 
	 * @param path
	 *            the relative path which begins on rootpath
	 * @param rootpath
	 *            an absolute path to a folder
	 * @return the merded absolute path without points
	 */
	private String createAbsolutPath(String path, String rootpath)
	{
		if (System.getProperty("os.name").contains("Windows"))
		{
			if (path.startsWith(":", 1))
				return path;
		}
		else
		{
			if (path.startsWith(FILESEPARATOR))
				return path;
		}

		String ret = (rootpath.endsWith(FILESEPARATOR) ? rootpath : (rootpath + FILESEPARATOR)) + path;
		while (ret.contains(FILESEPARATOR + "." + FILESEPARATOR) || ret.contains(FILESEPARATOR + ".." + FILESEPARATOR))
		{
			if (ret.contains(FILESEPARATOR + ".." + FILESEPARATOR))
			{
				String temp = ret.substring(0, ret.indexOf(FILESEPARATOR + ".."));
				temp = temp.substring(0, temp.lastIndexOf(FILESEPARATOR));
				ret = temp + ret.substring(ret.indexOf(FILESEPARATOR + "..") + 3);
			}
			else
			{
				ret = replaceAll(ret, FILESEPARATOR + "." + FILESEPARATOR, FILESEPARATOR);
			}
		}
		return ret;
	}

	/**
	 * a relaceAll Method which doesn't interprets the toreplace String as a
	 * regex and so you can also replace \ and such special things
	 * 
	 * @param text
	 *            the text who has to be modified
	 * @param toreplace
	 *            the text which has to be replaced
	 * @param replacement
	 *            the text which has to be inserted instead of toreplace
	 * @return the modified text with all toreplace parts replaced with
	 *         replacement
	 */
	public String replaceAll(String text, String toreplace, String replacement)
	{
		String ret = "";
		while (text.contains(toreplace))
		{
			ret += text.substring(0, text.indexOf(toreplace)) + replacement;
			text = text.substring(text.indexOf(toreplace) + toreplace.length());
		}
		ret += text;
		return ret;
	}    

	public String getFrancaVersion()
	{
		return Platform.getBundle("org.franca.core").getVersion().toString();
	}		
	
	public void setNoProxyCode() {
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, "false");
		ConsoleLogger.printLog("No proxy code will be generated");
	}

	public void setNoStubCode() {
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, "false");
		ConsoleLogger.printLog("No stub code will be generated");
	}

	public void setDefaultDirectory(String optionValue) {
		ConsoleLogger.printLog("Default output directory: " + optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_DEFAULT_SOMEIP, optionValue);
		// In the case where no other output directories are set, 
		// this default directory will be used for them
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, optionValue);
	}

	public void setCommonDirectory(String optionValue) {
		ConsoleLogger.printLog("Common output directory: " + optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, optionValue);
	}

	public void setProxyDirectory(String optionValue) {
		ConsoleLogger.printLog("Proxy output directory: " + optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, optionValue);
	}

	public void setStubtDirectory(String optionValue) {
		ConsoleLogger.printLog("Stub output directory: " + optionValue);
		someIpPref.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, optionValue);
	}

	public void setLogLevel(String optionValue) {
		if(PreferenceConstantsSomeIP.LOGLEVEL_QUIET.equals(optionValue)) {
			someIpPref.setPreference(PreferenceConstantsSomeIP.P_LOGOUTPUT_SOMEIP, "false");
			ConsoleLogger.enableLogging(false);
			ConsoleLogger.enableErrorLogging(false);
		}
		if(PreferenceConstantsSomeIP.LOGLEVEL_VERBOSE.equals(optionValue)) {
			someIpPref.setPreference(PreferenceConstantsSomeIP.P_LOGOUTPUT_SOMEIP, "true");
			ConsoleLogger.enableErrorLogging(true);
			ConsoleLogger.enableLogging(true);
		}
	}
	

}

