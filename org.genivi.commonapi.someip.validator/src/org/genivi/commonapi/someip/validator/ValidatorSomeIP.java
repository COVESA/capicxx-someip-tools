/* Copyright (C) 2013-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.validator;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Map.Entry;
import java.util.Set;

import org.eclipse.core.resources.IFile;
import org.eclipse.core.resources.ResourcesPlugin;
import org.eclipse.core.runtime.IPath;
import org.eclipse.core.runtime.Path;
import org.eclipse.emf.common.util.URI;
import org.eclipse.emf.ecore.EObject;
import org.eclipse.emf.ecore.EStructuralFeature;
import org.eclipse.emf.ecore.resource.Resource;
import org.eclipse.emf.ecore.resource.ResourceSet;
import org.eclipse.emf.ecore.resource.impl.ResourceSetImpl;
import org.eclipse.jface.preference.IPreferenceStore;
import org.eclipse.xtext.validation.ValidationMessageAcceptor;
import org.franca.core.dsl.validation.IFrancaExternalValidator;
import org.franca.core.franca.FArgument;
import org.franca.core.franca.FEnumerationType;
import org.franca.core.franca.FEnumerator;
import org.franca.core.franca.FInterface;
import org.franca.core.franca.FMapType;
import org.franca.core.franca.FMethod;
import org.franca.core.franca.FModel;
import org.franca.core.franca.FType;
import org.franca.core.franca.FTypeCollection;
import org.franca.core.franca.FTypeDef;
import org.franca.core.franca.FTypeRef;
import org.franca.core.franca.FrancaPackage;
import org.franca.core.franca.Import;
import org.genivi.commonapi.core.generator.FTypeCycleDetector;
import org.genivi.commonapi.core.generator.FrancaGeneratorExtensions;
import org.genivi.commonapi.someip.preferences.PreferenceConstantsSomeIP;
import org.genivi.commonapi.someip.ui.CommonApiSomeIPUiPlugin;
import org.genivi.commonapi.someip.validator.preference.ValidatorSomeIPPreferencesPage;
import org.osgi.framework.BundleReference;
import org.osgi.framework.Version;

import com.google.inject.Guice;

public class ValidatorSomeIP implements IFrancaExternalValidator
{

    private FTypeCycleDetector                            cycleDetector;
    private HashMap<String, HashSet<String>>              importList   = new HashMap<String, HashSet<String>>();
    private AllInfoMapsBuilder                            aimBuilder   = new AllInfoMapsBuilder();
    private Map<String, HashMap<String, HashSet<String>>> fastAllInfo  = new HashMap<String, HashMap<String, HashSet<String>>>();
    private Boolean                                       hasChanged   = false;
    private ResourceSet                                   resourceSet;
    private Set<EObject>                                  resourceList = new HashSet<EObject>();

    public ValidatorSomeIP()
    {
        cycleDetector = Guice.createInjector().getInstance(FTypeCycleDetector.class);
    }

    @Override
    public void validateModel(FModel model, ValidationMessageAcceptor messageAcceptor)
    {
        try {
            if (!isValidatorEnabled())
            {
                return;
            }
            resourceSet = new ResourceSetImpl();
            Resource res = model.eResource();
            URI uri = res.getURI();

            boolean isWorkspaceUri = res.getURI().isPlatform();
            IPath filePath;
            String filePathString;
            if (isWorkspaceUri)
            {
                Path platformPath = new Path(res.getURI().toPlatformString(true));
                IFile file = ResourcesPlugin.getWorkspace().getRoot().getFile(platformPath);
                filePath = file.getLocation();
                filePathString = file.getLocation().toString();
            }
            else
            {
                filePath = new Path(res.getURI().toFileString());
                filePathString = filePath.toString();
            }


            try
            {
                String cwd = filePath.removeLastSegments(1).toString();
                initImportList(model, cwd, filePathString);
                importList = buildImportList(importList);

                for (FTypeCollection fTypeCollection : model.getTypeCollections())
                {
                    validateImportedTypeCollections(model, messageAcceptor, filePath.lastSegment(), cwd, fTypeCollection);
                }
            }
            catch (NullPointerException e)
            {
            }


            if (isWorkspaceUri)
            {
                // That path segment logic works only for paths within an Eclipse Workspace, but not for the command line
                // which may point to files outside an Eclipse Workspace.
                int segCount = uri.segmentCount() - 2;
                String cwd = filePath.removeLastSegments(segCount).toString();
                if (isWholeWorkspaceCheckActive())
                {
                    if (aimBuilder.buildAllInfos(cwd))
                    {
                        fastAllInfo = aimBuilder.fastAllInfo;
                    }
                    else
                    {
                        if (!uri.segment(2).toString().equals("bin"))
                            aimBuilder.updateAllInfo(model, filePath.toString());
                        fastAllInfo = aimBuilder.fastAllInfo;
                    }
                }
                else
                {
                    resourceList.add(model);
                    aimBuilder.buildAllInfo(resourceList);
                }


                cwd = filePath.removeLastSegments(1).toString();
                for (FInterface fInterface : model.getInterfaces())
                {
                    validateImportedTypeCollections(model, messageAcceptor, filePath.lastSegment(), cwd, fInterface);
                }
            }

            for (FTypeCollection fTypeCollection : model.getTypeCollections())
            {
                validateTypeCollectionName(model, messageAcceptor, filePath, fTypeCollection);
                validateTypeCollectionElements(messageAcceptor, fTypeCollection);
            }

            for (FInterface fInterface : model.getInterfaces())
            {
                validateTypeCollectionName(model, messageAcceptor, filePath, fInterface);
                validateFInterfaceElements(messageAcceptor, fInterface);
            }
            resourceList.clear();
            importList.clear();
        }
        catch (Exception ex) {
            ex.printStackTrace();
            throw ex;
        }
    }

    // put all imports (with absolute path) of this model to a map
    private void initImportList(FModel model, String cwd, String filePath)
    {
        HashSet<String> importedFiles = new HashSet<String>();
        for (Import fImport : model.getImports())
        {
            Path absoluteImportPath = new Path(fImport.getImportURI());
            if (!absoluteImportPath.isAbsolute())
            {
                absoluteImportPath = new Path(cwd + "/" + fImport.getImportURI());
                importedFiles.add(absoluteImportPath.toString());
            }
            else
            {
                importedFiles.add(absoluteImportPath.toString().replaceFirst(absoluteImportPath.getDevice() + "/", ""));
            }
        }
        importList.put(filePath, importedFiles);
    }

    private EObject buildResource(String filename, String cwd)
    {
        URI fileURI = normalizeURI(URI.createURI(filename));
        URI cwdURI = normalizeURI(URI.createURI(cwd));
        Resource resource = null;

        if (cwd != null && cwd.length() > 0)
        {
            fileURI = URI.createURI((cwdURI.toString() + "/" + fileURI.toString()).replaceAll("/+", "/"));
        }

        try
        {
            resource = resourceSet.getResource(fileURI, true);
            resource.load(Collections.EMPTY_MAP);
        }
        catch (RuntimeException e)
        {
            return null;
        }
        catch (IOException io)
        {
            return null;
        }

        try
		{
            return resource.getContents().get(0);
        }
        catch (Exception e)
		{
            return null;
        }
    }

    private static URI normalizeURI(URI path)
    {
        if (path.isFile())
        {
            return URI.createURI(path.toString().replaceAll("\\\\", "/"));
        }
        return path;
    }

    private HashMap<String, HashSet<String>> buildImportList(HashMap<String, HashSet<String>> rekImportList)
    {
        HashMap<String, HashSet<String>> helpMap = new HashMap<String, HashSet<String>>();
        for (Entry<String, HashSet<String>> entry : rekImportList.entrySet())
        {
            for (String importedPath : entry.getValue())
            {
                if (!rekImportList.containsKey(importedPath))
                {
                    hasChanged = true;
                    HashSet<String> importedFIDL = new HashSet<String>();
                    EObject resource = null;
                    resource = buildResource(importedPath.substring(importedPath.lastIndexOf("/") + 1, importedPath.length()), "file:/"
                            + importedPath.substring(0, importedPath.lastIndexOf("/") + 1));
                    if (resource != null)
                    {
                        resourceList.add(resource);
                        for (EObject imp : resource.eContents())
                        {
                            if (imp instanceof Import)
                            {
                                Path importImportedPath = new Path(((Import) imp).getImportURI());
                                if (importImportedPath.isAbsolute())
                                {
                                    importedFIDL.add(importImportedPath.toString().replaceFirst(importImportedPath.getDevice() + "/", ""));
                                }
                                else
                                {
                                    importImportedPath = new Path(importedPath.substring(0, importedPath.lastIndexOf("/")) + "/"
                                            + ((Import) imp).getImportURI());
                                    importedFIDL.add(importImportedPath.toString());
                                }
                            }
                        }
                    }
                    helpMap.put(importedPath, importedFIDL);
                }
            }
        }
        if (hasChanged)
        {
            hasChanged = false;
            helpMap.putAll(rekImportList);
            return buildImportList(helpMap);
        }
        else
        {
            return rekImportList;
        }
    }

    private void validateTypeCollectionName(FModel model, ValidationMessageAcceptor messageAcceptor, IPath filePath,
            FTypeCollection fTypeCollection)
    {
        String typeCollectionName = fTypeCollection.getName();
        if (typeCollectionName != null)
        {
            if (typeCollectionName.contains("."))
            {
                acceptError("Name may not contain '.'", fTypeCollection, FrancaPackage.Literals.FMODEL_ELEMENT__NAME, -1, messageAcceptor);
            }

            // since Franca 0.8.10 is released, this check is unnecessary
            if (!isFrancaVersionGreaterThan(0, 8, 9))
            {
                if (fastAllInfo.get(typeCollectionName).get(model.getName()).size() > 1)
                {
                    for (String s : fastAllInfo.get(typeCollectionName).get(model.getName()))
                    {
                        if (!s.equals(filePath.toString()))
                        {
                            if (importList.containsKey(s))
                            {
                                acceptError("Imported file " + s + " has interface or typeCollection with the same name and same package!",
                                        fTypeCollection, FrancaPackage.Literals.FMODEL_ELEMENT__NAME, -1, messageAcceptor);
                            }
                            else
                            {
                                acceptWarning("Interface or typeCollection in file " + s + " has the same name and same package!",
                                        fTypeCollection, FrancaPackage.Literals.FMODEL_ELEMENT__NAME, -1, messageAcceptor);
                            }
                        }
                    }
                }
            }
        }
    }

    private void validateTypeCollectionElements(ValidationMessageAcceptor messageAcceptor, FTypeCollection fTypeCollection)
    {
        for (FType fType : fTypeCollection.getTypes())
        {
            if (fType instanceof FMapType)
            {
                validateMapKey((FMapType) fType, messageAcceptor);
            }

            if (fType instanceof FEnumerationType)
            {
                for (FEnumerator fEnumerator : ((FEnumerationType) fType).getEnumerators())
                {
                    if (fEnumerator.getValue() != null)
                    {
                        String enumeratorValue = FrancaGeneratorExtensions.getEnumeratorValue(fEnumerator.getValue());
                        if (enumeratorValue != null)
                        {
                            enumeratorValue = enumeratorValue.toLowerCase();
                            validateEnumerationValue(enumeratorValue, messageAcceptor, fEnumerator);
                        }
                    }
                }
            }
        }
    }

    private void validateImportedTypeCollections(FModel model, ValidationMessageAcceptor messageAcceptor, String fileName, String cwd,
            FTypeCollection fTypeCollection)
    {
        String type = "typeCollection name";
        if (fTypeCollection instanceof FInterface)
            type = "interface name";
        for (Entry<String, Triple<String, ArrayList<String>, ArrayList<String>>> entry : aimBuilder.allInfo.entrySet())
        {
            if (!entry.getKey().equals(cwd + "/" + fileName))
            {
                Triple<String, ArrayList<String>, ArrayList<String>> entryValue = entry.getValue();
                if (entryValue.packageName != null)
                {
                    if (entryValue.packageName.startsWith(model.getName() + "." + fTypeCollection.getName()))
                    {
                        HashSet<String> importPaths = importList.get(cwd + "/" + fileName);
                        if (importPaths != null)
                        {
                            if (importPaths.contains(entry.getKey()))
                            {
                                acceptError(
                                        "Imported file's package " + entryValue.packageName + " may not start with package "
                                                + model.getName() + " + " + type + " " + fTypeCollection.getName(), fTypeCollection,
                                        FrancaPackage.Literals.FMODEL_ELEMENT__NAME, -1, messageAcceptor);
                            }
                            else
                            {
                                acceptWarning(
                                        "File's package " + entryValue.packageName + " starts with package "
                                                + model.getName() + " + " + type + " " + fTypeCollection.getName(), fTypeCollection, null, -1,
                                        messageAcceptor);
                            }
                        }
                    }
                }
            }
        }
    }

    private void validateEnumerationValue(String enumeratorValue, ValidationMessageAcceptor messageAcceptor, FEnumerator fEnumerator)
    {
        String value = enumeratorValue;
        if (value.length() == 0)
        {
            acceptWarning("Missing value!", fEnumerator, FrancaPackage.Literals.FENUMERATOR__VALUE, -1, messageAcceptor);
            return;
        }

        if (value.length() == 1)
        {
            if (48 > value.charAt(0) || value.charAt(0) > 57)
            {
                acceptWarning("Not a valid number!", fEnumerator, FrancaPackage.Literals.FENUMERATOR__VALUE, -1, messageAcceptor);
                return;
            }
        }

        if (value.length() > 2)
        {
            if (value.charAt(0) == '0')
            {
                // binary
                if (value.charAt(1) == 'b')
                {
                    for (int i = 2; i < value.length(); i++)
                    {
                        if (value.charAt(i) != '0' && value.charAt(i) != '1')
                        {
                            acceptWarning("Not a valid number! Should be binary", fEnumerator, FrancaPackage.Literals.FENUMERATOR__VALUE,
                                    -1, messageAcceptor);
                            return;
                        }
                    }
                    return;
                }
                // hex
                if (value.charAt(1) == 'x')
                {
                    for (int i = 2; i < value.length(); i++)
                    {
                        if ((48 > value.charAt(i) || value.charAt(i) > 57)
                                && (97 > value.charAt(i) || value.charAt(i) > 102))
                        {
                            acceptWarning("Not a valid number! Should be hexadecimal", fEnumerator,
                                    FrancaPackage.Literals.FENUMERATOR__VALUE, -1, messageAcceptor);
                            return;
                        }
                    }
                    return;
                }
            }
        }
        if (value.charAt(0) == '0')
        {
            // oct
            for (int i = 1; i < value.length(); i++)
            {
                if (48 > value.charAt(i) || value.charAt(i) > 55)
                {
                    acceptWarning("Not a valid number! Should be octal", fEnumerator, FrancaPackage.Literals.FENUMERATOR__VALUE, -1,
                            messageAcceptor);
                    return;
                }
            }
            return;
        }
        // dec
        for (int i = 0; i < value.length(); i++)
        {
            if (48 > value.charAt(i) || value.charAt(i) > 57)
            {
                acceptWarning("Not a valid number! Should be decimal", fEnumerator, FrancaPackage.Literals.FENUMERATOR__VALUE, -1,
                        messageAcceptor);
                return;
            }
        }
    }

    private void validateFInterfaceElements(ValidationMessageAcceptor messageAcceptor, FInterface fInterface)
    {
        for (FMethod fMethod : fInterface.getMethods())
        {
            for (FArgument out : fMethod.getOutArgs())
            {
                validateMethodArgument(messageAcceptor, fMethod, out);
            }
            for (FArgument in : fMethod.getInArgs())
            {
                validateMethodArgument(messageAcceptor, fMethod, in);
            }
        }
    }

    private void validateMethodArgument(ValidationMessageAcceptor messageAcceptor, FMethod fMethod, FArgument arg)
    {
        if (arg.getName().equals(fMethod.getName()))
        {
            acceptError("Parameters cannot share name with method", arg, FrancaPackage.Literals.FMODEL_ELEMENT__NAME, -1, messageAcceptor);
        }
    }

    private void validateMapKey(FMapType m, ValidationMessageAcceptor messageAcceptor)
    {
        if (cycleDetector.hasCycle(m))
        {
            return;
        }

        FTypeRef key = m.getKeyType();
        if (isTypeAcceptableAsMapKey(key))
        {
            return;
        }

        while (key.getDerived() instanceof FTypeDef)
        {
            key = ((FTypeDef) key.getDerived()).getActualType();

            if (isTypeAcceptableAsMapKey(key))
            {
                return;
            }
        }

        acceptError("Key type has to be an primitive type!", m, FrancaPackage.Literals.FMAP_TYPE__KEY_TYPE, -1, messageAcceptor);
    }

    private boolean isTypeAcceptableAsMapKey(FTypeRef typeRef)
    {
        boolean accepted = false;

        if (!typeRef.getPredefined().toString().equals("undefined"))
        {
            accepted = true; // basic types are ok
        }
        else if (typeRef.getDerived() instanceof FEnumerationType)
        {
            accepted = true; // enums are also ok
        }

        return accepted;
    }

    private boolean isWholeWorkspaceCheckActive()
    {
        return CommonApiSomeIPUiPlugin.getValidatorPreferences().getBoolean(ValidatorSomeIPPreferencesPage.ENABLED_WORKSPACE_CHECK);
    }

    private boolean isFrancaVersionGreaterThan(int major, int minor, int micro)
    {
        Version francaVersion = ((BundleReference) FArgument.class.getClassLoader()).getBundle().getVersion();
        if (francaVersion.getMajor() > major)
        {
            return true;
        }
        if (francaVersion.getMajor() < major)
        {
            return false;
        }
        if (francaVersion.getMinor() > minor)
        {
            return true;
        }
        if (francaVersion.getMinor() < minor)
        {
            return false;
        }
        if (francaVersion.getMicro() > micro)
        {
            return true;
        }
        if (francaVersion.getMicro() < micro)
        {
            return false;
        }
        return false;
    }

    public boolean isValidatorEnabled()
    {
        IPreferenceStore prefs = CommonApiSomeIPUiPlugin.getValidatorPreferences();
        return prefs != null && prefs.getBoolean(PreferenceConstantsSomeIP.P_ENABLE_SOMEIP_VALIDATOR);
    }

    private void acceptError(String message, EObject object, EStructuralFeature feature, int index,
            ValidationMessageAcceptor messageAcceptor)
    {
        messageAcceptor.acceptError("Some/IP validation: " + message, object, feature, index, null);
    }

    private void acceptWarning(String message, EObject object, EStructuralFeature feature, int index,
            ValidationMessageAcceptor messageAcceptor)
    {
        messageAcceptor.acceptWarning("Some/IP validation: " + message, object, feature, index, null);
    }
}
