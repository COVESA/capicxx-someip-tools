package org.genivi.commonapi.someip.preferences;

import org.genivi.commonapi.core.preferences.PreferenceConstants;


public interface PreferenceConstantsSomeIP extends PreferenceConstants
{
    public static final String SCOPE                   = "org.genivi.commonapi.someip.ui";
    public static final String PROJECT_PAGEID          = "org.genivi.commonapi.someip.ui.preferences.CommonAPISomeIPPreferencePage";

    // preference keys
    public static final String P_LICENSE_SOMEIP        	= P_LICENSE;
    public static final String P_OUTPUT_PROXIES_SOMEIP  = P_OUTPUT_PROXIES;
    public static final String P_OUTPUT_STUBS_SOMEIP    = P_OUTPUT_STUBS;
	public static final String P_OUTPUT_COMMON_SOMEIP   = P_OUTPUT_COMMON;
	public static final String P_OUTPUT_DEFAULT_SOMEIP  = P_OUTPUT_DEFAULT;
	public static final String P_OUTPUT_SUBDIRS_SOMEIP  = P_OUTPUT_SUBDIRS;
    public static final String P_GENERATEPROXY_SOMEIP   = P_GENERATE_PROXY;
    public static final String P_GENERATESTUB_SOMEIP    = P_GENERATE_STUB;
    public static final String P_GENERATE_COMMON_SOMEIP	= P_GENERATE_COMMON;    
	public static final String P_LOGOUTPUT_SOMEIP       = P_LOGOUTPUT;
	public static final String P_USEPROJECTSETTINGS_SOMEIP= P_USEPROJECTSETTINGS;
	public static final String P_GENERATE_CODE_SOMEIP   = P_GENERATE_CODE;
	public static final String P_GENERATE_DEPENDENCIES_SOMEIP = P_GENERATE_DEPENDENCIES;
	public static final String P_GENERATE_SYNC_CALLS_SOMEIP = P_GENERATE_SYNC_CALLS;
    public static final String P_ENABLE_SOMEIP_VALIDATOR= "enableSomeIPValidator";
    public static final String P_ENABLE_SOMEIP_DEPLOYMENT_VALIDATOR = "enableSomeIPDeploymentValidator";

	// preference values
    public static final String DEFAULT_OUTPUT_SOMEIP   	= "./src-gen/";
}
