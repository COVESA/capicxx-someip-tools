/* Copyright (C) 2013 BMW Group
 * Author: Manfred Bathelt (manfred.bathelt@bmw.de)
 * Author: Juergen Gehring (juergen.gehring@bmw.de)
 * This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.ui;

import org.eclipse.xtext.generator.IGenerator;
import org.genivi.commonapi.core.ui.CommandExecutableExtensionFactory;
import org.genivi.commonapi.someip.generator.FrancaSomeIPGenerator;
import org.osgi.framework.Bundle;

import com.google.inject.Binder;

public class SomeIPCommandExecutableExtensionFactory extends CommandExecutableExtensionFactory
{
    @Override
    protected Bundle getBundle()
    {
        return CommonApiSomeIPUiPlugin.getInstance().getBundle();
    }

    @Override
    protected void bindGeneratorClass(Binder binder)
    {
        binder.bind(IGenerator.class).to(FrancaSomeIPGenerator.class);
    }
}
