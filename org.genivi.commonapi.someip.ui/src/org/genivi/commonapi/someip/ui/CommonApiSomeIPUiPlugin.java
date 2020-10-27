/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.ui;

import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.ui.plugin.AbstractUIPlugin;
import org.osgi.framework.BundleContext;

public class CommonApiSomeIPUiPlugin extends AbstractUIPlugin
{
    public static final String             PLUGIN_ID = "org.genivi.commonapi.someip.ui"; //$NON-NLS-1$

    private static CommonApiSomeIPUiPlugin INSTANCE;

    public CommonApiSomeIPUiPlugin()
    {
    }

    @Override
    public void start(final BundleContext context) throws Exception
    {
        super.start(context);
        INSTANCE = this;
    }

    @Override
    public void stop(final BundleContext context) throws Exception
    {
        INSTANCE = null;
        super.stop(context);
    }

    public static CommonApiSomeIPUiPlugin getInstance()
    {
        return INSTANCE;
    }

    public static CommonApiSomeIPUiPlugin getDefault()
    {
        return INSTANCE;
    }

    public static IPreferenceStore getValidatorPreferences() {
        return INSTANCE.getPreferenceStore();
    }
}
