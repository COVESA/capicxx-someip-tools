/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.someip.ui.handler;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.IProject;
import org.eclipse.core.resources.IResource;
import org.eclipse.core.runtime.CoreException;
import org.eclipse.core.runtime.NullProgressMonitor;
import org.eclipse.core.runtime.QualifiedName;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.xtext.builder.EclipseResourceFileSystemAccess2;
import org.genivi.commonapi.core.preferences.PreferenceConstants;
import org.genivi.commonapi.core.ui.handler.GenerationCommand;
import org.genivi.commonapi.someip.preferences.FPreferencesSomeIP;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;
import org.genivi.commonapi.someip.ui.CommonApiSomeIPUiPlugin;

public class SomeIPGenerationCommand extends GenerationCommand {

	/**
	 * Init Some/Ip preferences
	 * @param page
	 * @param project
	 */
	@Override
	protected void setupPreferences(IFile file) {

		initSomeIpPreferences(file, CommonApiSomeIPUiPlugin.getDefault().getPreferenceStore());
	}	

	@Override
	protected EclipseResourceFileSystemAccess2 createFileSystemAccess() {

		final EclipseResourceFileSystemAccess2 fsa = fileAccessProvider.get();

		fsa.setOutputConfigurations(FPreferencesSomeIP.getInstance().getOutputpathConfiguration());

		fsa.setMonitor(new NullProgressMonitor());

		return fsa;
	}	
	
	/**
	 * Set the properties for the code generation from the resource properties (set with the property page, via the context menu).
	 * Take default values from the eclipse preference page.
	 * @param file 
	 * @param store - the eclipse preference store
	 */
	public void initSomeIpPreferences(IFile file, IPreferenceStore store)
	{
		FPreferencesSomeIP instance = FPreferencesSomeIP.getInstance();

		String outputFolderCommon = null;
		String outputFolderProxies = null;
		String outputFolderStubs = null;
		String licenseHeader = null;		
		String generateProxy = null;
		String generatStub = null;		
		
		IProject project = file.getProject();
		IResource resource = file;
		
		try {
			// Should project or file specific properties be used ?
			String useProject1 = project.getPersistentProperty(new QualifiedName(PreferenceConstants.PROJECT_PAGEID, PreferenceConstants.P_USEPROJECTSETTINGS));
			String useProject2 = file.getPersistentProperty(new QualifiedName(PreferenceConstants.PROJECT_PAGEID, PreferenceConstants.P_USEPROJECTSETTINGS));
			if("true".equals(useProject1) || "true".equals(useProject2)) {
				resource = project;
			} 
			outputFolderCommon = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP));
			outputFolderProxies = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP));
			outputFolderStubs = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP));
			licenseHeader = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_LICENSE_SOMEIP));
			generateProxy = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP));
			generatStub = resource.getPersistentProperty(new QualifiedName(PreferenceConstantsSomeIP.PROJECT_PAGEID, PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP));
			
		} catch (CoreException e1) {
			System.err.println("Failed to get property for " + resource.getName());
		}
		// Set defaults from the preferences in the very first case, where nothing was specified from the user.
		if(outputFolderCommon == null) {
			outputFolderCommon = store.getString(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP);			
		}
		if(outputFolderProxies == null) {
			outputFolderProxies = store.getString(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP);			
		}
		if(outputFolderStubs == null) {
			outputFolderStubs = store.getString(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP);	
		}
		if(licenseHeader == null) {
			licenseHeader = store.getString(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP);			
		}
		if(generateProxy == null) {
			generateProxy = store.getString(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP);
		}
		if(generatStub == null) {
			generatStub = store.getString(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP);
		}		
		// finally, store the properties for the code generator
		instance.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, outputFolderCommon);
		instance.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, outputFolderProxies);
		instance.setPreference(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, outputFolderStubs);
		instance.setPreference(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, licenseHeader);
		instance.setPreference(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, generateProxy);
		instance.setPreference(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, generatStub);		
	}
}