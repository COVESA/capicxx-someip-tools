package org.genivi.commonapi.someip.preferences;


public interface PreferenceConstantsSomeIP
{
    public static final String SCOPE                   = "org.genivi.commonapi.someip.ui";
    public static final String PROJECT_PAGEID          = "org.genivi.commonapi.someip.ui.preferences.CommonAPISomeIPPreferencePage";

    // preference keys
    public static final String P_LICENSE_SOMEIP        	= "licenseHeaderSomeIP";
    public static final String P_OUTPUT_PROXIES_SOMEIP  = "outputDirProxies";
    public static final String P_OUTPUT_STUBS_SOMEIP    = "outputDirStubs";
	public static final String P_OUTPUT_COMMON_SOMEIP   = "outputDirCommon";
	public static final String P_OUTPUT_DEFAULT_SOMEIP  = "outputDirDefault";
    public static final String P_GENERATEPROXY_SOMEIP   = "generateproxySomeIP";
    public static final String P_GENERATESTUB_SOMEIP    = "generatestubSomeIP";
	public static final String P_LOGOUTPUT_SOMEIP       = "logoutput";
	public static final String P_USEPROJECTSETTINGS_SOMEIP= "useProjectSettings";
	public static final String P_GENERATE_CODE_SOMEIP   = "generateCode";
	public static final String P_GENERATE_DEPENDENCIES_SOMEIP = "generateDependencies";
	public static final String P_GENERATE_SYNC_CALLS_SOMEIP = "generateSyncCalls";
    public static final String P_ENABLE_SOMEIP_VALIDATOR= "enableSomeIPValidator";
    public static final String P_ENABLE_SOMEIP_DEPLOYMENT_VALIDATOR = "enableSomeIPDeploymentValidator";

	// preference values
    public static final String DEFAULT_OUTPUT_SOMEIP   	= "./src-gen/";
	public static final String LOGLEVEL_QUIET			= "quiet";
	public static final String LOGLEVEL_VERBOSE			= "verbose";
    public static final String DEFAULT_LICENSE_SOMEIP   = "This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0.\n"
    													+ "If a copy of the MPL was not distributed with this file, You can obtain one at\n"
    													+ "http://mozilla.org/MPL/2.0/.";
	public static final String NO_CODE                  = "";

}
