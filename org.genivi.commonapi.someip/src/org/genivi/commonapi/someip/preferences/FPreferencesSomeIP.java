/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.preferences;


import java.util.HashMap;
import java.util.Map;
import java.io.File;

import org.eclipse.xtext.generator.IFileSystemAccess;
import org.eclipse.xtext.generator.OutputConfiguration;
import org.franca.core.franca.FModel;

public class FPreferencesSomeIP
{

    private static FPreferencesSomeIP instance    = null;
    private Map<String, String> preferences = null;

    private FPreferencesSomeIP()
    {
        preferences = new HashMap<String, String>();
        clidefPreferences();
    }

    public void resetPreferences()
    {
        preferences.clear();
    }

    public Map<String, String> getPreferences() {
		return preferences;
	}    
    
    
    public static FPreferencesSomeIP getInstance()
    {
        if (instance == null) {
            instance = new FPreferencesSomeIP();
        }
        return instance;
    }

    public void clidefPreferences()
    {
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_OUTPUT_DEFAULT_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_OUTPUT_DEFAULT_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        }    	
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        }    	
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_OUTPUT_SUBDIRS_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_OUTPUT_SUBDIRS_SOMEIP, "false");
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_LICENSE);
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, "true");
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, "true");
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATE_COMMON_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATE_COMMON_SOMEIP, "true");
        }        
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATE_CODE_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATE_CODE_SOMEIP, "true");    
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATE_DEPENDENCIES_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATE_DEPENDENCIES_SOMEIP, "true");    
        }
        if (!preferences.containsKey(PreferenceConstantsSomeIP.P_GENERATE_SYNC_CALLS_SOMEIP)) {
            preferences.put(PreferenceConstantsSomeIP.P_GENERATE_SYNC_CALLS_SOMEIP, "true");    
        }
    }

    public String getPreference(String preferencename, String defaultValue) {
    	
    	if (preferences.containsKey(preferencename)) {
    		return preferences.get(preferencename);
    	}
    	System.err.println("Unknown preference " + preferencename);
        return "";
    }
    
    public void setPreference(String name, String value) {
        if(preferences != null) {
        	preferences.put(name, value);
        }
    }
 
    public String getModelPath(FModel model)
    {
        String ret = model.eResource().getURI().toString();
        return ret;
    }

    /**
     * Set the output path configurations (based on stored preference values) for file system access types 
     * (instance of AbstractFileSystemAccess)
     * @return
     */
    public HashMap<String, OutputConfiguration> getOutputpathConfiguration() {
        return getOutputpathConfiguration(null);
    }

    /**
     * Set the output path configurations (based on stored preference values) for file system access types
     * (instance of AbstractFileSystemAccess)
     * @subdir the subdir to use, can be null
     * @return
     */
    public HashMap<String, OutputConfiguration> getOutputpathConfiguration(String subdir) {
        String defaultDir = getPreference(PreferenceConstantsSomeIP.P_OUTPUT_DEFAULT_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        String commonDir = getPreference(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, defaultDir);
        String outputProxyDir = getPreference(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, defaultDir);
        String outputStubDir = getPreference(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, defaultDir);

        if (null != subdir && getPreference(PreferenceConstantsSomeIP.P_OUTPUT_SUBDIRS_SOMEIP, "false").equals("true")) {
            defaultDir = new File(defaultDir, subdir).getPath();
            commonDir = new File(commonDir, subdir).getPath();
            outputProxyDir = new File(outputProxyDir, subdir).getPath();
            outputStubDir = new File(outputStubDir, subdir).getPath();
        }

        HashMap<String, OutputConfiguration>  outputs = new HashMap<String, OutputConfiguration> ();

        OutputConfiguration commonOutput = new OutputConfiguration(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP);
        commonOutput.setDescription("Common Output Folder");
        commonOutput.setOutputDirectory(commonDir);
        commonOutput.setCreateOutputDirectory(true);
        outputs.put(IFileSystemAccess.DEFAULT_OUTPUT, commonOutput);
        
        OutputConfiguration proxyOutput = new OutputConfiguration(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP);
        proxyOutput.setDescription("Proxy Output Folder");
        proxyOutput.setOutputDirectory(outputProxyDir);
        proxyOutput.setCreateOutputDirectory(true);
        outputs.put(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, proxyOutput);
        
        OutputConfiguration stubOutput = new OutputConfiguration(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP);
        stubOutput.setDescription("Stub Output Folder");
        stubOutput.setOutputDirectory(outputStubDir);
        stubOutput.setCreateOutputDirectory(true);
        outputs.put(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, stubOutput);
        
        return outputs;
    }
    
}
