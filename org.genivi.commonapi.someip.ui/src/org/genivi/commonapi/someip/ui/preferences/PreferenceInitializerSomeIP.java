/*
 * Copyright (C) 2013 BMW Group Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de) This Source Code Form is
 * subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the
 * MPL was not distributed with this file, You can obtain one at
 * http://mozilla.org/MPL/2.0/.
 */

package org.genivi.commonapi.someip.ui.preferences;

import org.eclipse.core.runtime.preferences.AbstractPreferenceInitializer;
import org.eclipse.jface.preference.IPreferenceStore;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;
import org.genivi.commonapi.someip.ui.CommonApiSomeIPUiPlugin;

/**
 * Class used to initialize default preference values.
 */
public class PreferenceInitializerSomeIP extends AbstractPreferenceInitializer
{

    /*
     * (non-Javadoc)
     * 
     * @see org.eclipse.core.runtime.preferences.AbstractPreferenceInitializer#
     * initializeDefaultPreferences()
     */
    public void initializeDefaultPreferences()
    {
        IPreferenceStore store = CommonApiSomeIPUiPlugin.getDefault().getPreferenceStore();
        store.setDefault(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_LICENSE_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_USEPROJECTSETTINGS_SOMEIP, false);        
    }
}
