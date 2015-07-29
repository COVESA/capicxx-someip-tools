/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

package org.genivi.commonapi.someip.validator.preference;

import org.eclipse.jface.preference.BooleanFieldEditor;
import org.eclipse.jface.preference.FieldEditorPreferencePage;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.ui.IWorkbench;
import org.eclipse.ui.IWorkbenchPreferencePage;
import org.genivi.commonapi.core.ui.CommonApiUiPlugin;

public class ValidatorSomeIPPreferencesPage extends FieldEditorPreferencePage implements IWorkbenchPreferencePage
{

    public final static String ENABLED_SOMEIP_VALIDATOR = "ENABLED_SOMEIP_VALIDATOR";
    public final static String ENABLED_WORKSPACE_CHECK  = "ENABLED_WORKSPACE_CHECK";

    @Override
    public void checkState()
    {
        super.checkState();
    }

    @Override
    public void createFieldEditors()
    {
        addField(new BooleanFieldEditor(ENABLED_SOMEIP_VALIDATOR, "validator enabled", getFieldEditorParent()));
        addField(new BooleanFieldEditor(ENABLED_WORKSPACE_CHECK,
                "enable the whole workspace check (Note: Validations takes up to two minutes if enabled)", getFieldEditorParent()));
    }

    @Override
    public void init(IWorkbench workbench)
    {
        IPreferenceStore prefStore = CommonApiUiPlugin.getDefault().getPreferenceStore();
        setPreferenceStore(prefStore);
        setDescription("Disable or enable the Some/IP validator!");
        prefStore.setDefault(ValidatorSomeIPPreferencesPage.ENABLED_SOMEIP_VALIDATOR, true);

    }

}
