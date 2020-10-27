/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.ui.preferences;

import org.eclipse.core.runtime.preferences.DefaultScope;
import org.eclipse.jface.preference.BooleanFieldEditor;
import org.eclipse.jface.preference.FieldEditor;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.jface.preference.StringFieldEditor;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.genivi.commonapi.core.ui.preferences.FieldEditorOverlayPage;
import org.genivi.commonapi.core.ui.preferences.MultiLineStringFieldEditor;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;
import org.genivi.commonapi.someip.ui.CommonApiSomeIPUiPlugin;

/**
 * This class represents a preference page that is contributed to the
 * Preferences dialog. By subclassing <samp>FieldEditorOverlayPage</samp>.
 * <p>
 * This page is used to modify preferences. They are stored in the preference store that
 * belongs to the main plug-in class.
 */

public class CommonAPISomeIPPreferencePage extends FieldEditorOverlayPage implements IWorkbenchPreferencePage
{
    private FieldEditor         license     = null;
    private FieldEditor         proxyOutput = null;
    private FieldEditor         stubOutput  = null;
    private FieldEditor         commonOutput  = null;
    private BooleanFieldEditor  deploymentValidation;


    public CommonAPISomeIPPreferencePage()
    {
        super(GRID);
    }

    /**
     * Creates the field editors. Field editors are abstractions of the common
     * GUI blocks needed to manipulate various types of preferences. Each field
     * editor knows how to save and restore itself.
     */
    @Override
    public void createFieldEditors()
    {
        deploymentValidation = new BooleanFieldEditor(PreferenceConstantsSomeIP.P_ENABLE_SOMEIP_DEPLOYMENT_VALIDATOR, "Validate deployment", getFieldEditorParent());
        addField(deploymentValidation);

        license = new MultiLineStringFieldEditor(PreferenceConstantsSomeIP.P_LICENSE_SOMEIP, "The header to insert for all generated files", 60,
                getFieldEditorParent());
        license.setLabelText(""); // need to set this parameter (seems to be a bug)
        addField(license);
        commonOutput = new StringFieldEditor(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP,
                "Output directory for the common part", 30, getFieldEditorParent());
        addField(commonOutput);
        proxyOutput = new StringFieldEditor(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP,
                "Output directory for proxies inside project", 30, getFieldEditorParent());
        addField(proxyOutput);
        stubOutput = new StringFieldEditor(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP, "Output directory for stubs inside project",
                30, getFieldEditorParent());
        addField(stubOutput);
    }

    @Override
    protected void performDefaults()
    {
    	if(!projectSettingIsActive) {
    		DefaultScope.INSTANCE.getNode(PreferenceConstantsSomeIP.SCOPE).put(PreferenceConstantsSomeIP.P_OUTPUT_COMMON_SOMEIP,
    				PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
    		DefaultScope.INSTANCE.getNode(PreferenceConstantsSomeIP.SCOPE).put(PreferenceConstantsSomeIP.P_OUTPUT_PROXIES_SOMEIP,
    				PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);
    		DefaultScope.INSTANCE.getNode(PreferenceConstantsSomeIP.SCOPE).put(PreferenceConstantsSomeIP.P_OUTPUT_STUBS_SOMEIP,
    				PreferenceConstantsSomeIP.DEFAULT_OUTPUT_SOMEIP);

    		super.performDefaults();
    	}
    }

    @Override
    public void init(IWorkbench workbench)
    {
        if (!isPropertyPage())
            setPreferenceStore(CommonApiSomeIPUiPlugin.getDefault().getPreferenceStore());
    }

    @Override
    protected String getPageId()
    {
        return PreferenceConstantsSomeIP.PROJECT_PAGEID;
    }

    @Override
    protected IPreferenceStore doGetPreferenceStore()
    {
        return CommonApiSomeIPUiPlugin.getDefault().getPreferenceStore();
    }

    @Override
    public boolean performOk()
    {
    	if(!projectSettingIsActive) {
    		boolean result = super.performOk();

    		return result;
    	}
    	return true;
    }

}
