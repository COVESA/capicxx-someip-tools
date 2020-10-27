/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
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
    @Override
    public void initializeDefaultPreferences()
    {
        IPreferenceStore store = CommonApiSomeIPUiPlugin.getDefault().getPreferenceStore();
        store.setDefault(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_LICENSE);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP, PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATE_COMMON_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATEPROXY_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATESTUB_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_USEPROJECTSETTINGS_SOMEIP, false);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATE_CODE_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATE_DEPENDENCIES_SOMEIP, true);
        store.setDefault(PreferenceConstantsSomeIP.P_ENABLE_SOMEIP_VALIDATOR, true);
        store.setDefault(PreferenceConstantsSomeIP.P_ENABLE_SOMEIP_DEPLOYMENT_VALIDATOR, true);
        store.setDefault(PreferenceConstantsSomeIP.P_GENERATE_SYNC_CALLS_SOMEIP, true);
    }
}
