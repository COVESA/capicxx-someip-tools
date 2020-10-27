/* Copyright (C) 2014-2020 Bayerische Motoren Werke Aktiengesellschaft (BMW AG)
   This Source Code Form is subject to the terms of the Mozilla Public
   License, v. 2.0. If a copy of the MPL was not distributed with this
   file, You can obtain one at http://mozilla.org/MPL/2.0/. */
package org.genivi.commonapi.someip.cli;

import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.genivi.commonapi.console.AbstractCommandLineHandler;
import org.genivi.commonapi.console.ConsoleLogger;
import org.genivi.commonapi.console.ICommandLineHandler;

/**
 * Handle command line options
 */
public class CommandLineHandlerSomeIp extends AbstractCommandLineHandler implements ICommandLineHandler
{

    public static final String      FILE_EXTENSION_FDEPL = "fdepl";
    public static final String      FILE_EXTENSION_FIDL  = "fidl";
    private SomeIPCommandlineToolMain cliTool;

    public CommandLineHandlerSomeIp()
    {
    	cliTool = new SomeIPCommandlineToolMain();
    }

    @Override
    public int excute(CommandLine parsedArguments)
    {
		@SuppressWarnings("unchecked")
		List<String> files = parsedArguments.getArgList();

		// a search path may be specified, collect all fdepl files
		if(parsedArguments.hasOption("sp")) {
			files.addAll(cliTool.searchFdeplFiles(parsedArguments.getOptionValue("sp")));
		}
		// We expect at least one fdepl file
		if(files.size() > 0 && files.get(0) != null) {
			String file = files.get(0);
			if(file.endsWith(FILE_EXTENSION_FDEPL)) {
				// handle command line options

				// -ll --loglevel quiet or verbose
				if(parsedArguments.hasOption("ll")) {
					cliTool.setLogLevel(parsedArguments.getOptionValue("ll"));
				}
				ConsoleLogger.printLog("Executing CommonAPI SomeIP Code Generation...\n");

				// Switch off generation of proxy code
				// -np --no-proxy do not generate proxy code
				if(parsedArguments.hasOption("np")) {
					cliTool.setNoProxyCode();
				}

				// Switch off generation of stub code
				// -ns --no-stub do not generate stub code
				if(parsedArguments.hasOption("ns")) {
					cliTool.setNoStubCode();
				}

				// destination: -d --dest overwrite default directory
				if(parsedArguments.hasOption("d")) {
					cliTool.setDefaultDirectory(parsedArguments.getOptionValue("d"));
				}

				// destination: -dsub --dest-subdirs use destination/<filename>/ subdirs
				// as dest directory
				if(parsedArguments.hasOption("dsub")) {
					cliTool.setDestinationSubdirs();
				}

				// destination: -dc --dest-common overwrite target directory for common part
				if(parsedArguments.hasOption("dc")) {
					cliTool.setCommonDirectory(parsedArguments.getOptionValue("dc"));
				}

				// destination: -dp --dest-proxy overwrite target directory for proxy code
				if(parsedArguments.hasOption("dp")) {
					cliTool.setProxyDirectory(parsedArguments.getOptionValue("dp"));
				}

				// destination: -ds --dest-stub overwrite target directory for stub code
				if(parsedArguments.hasOption("ds")) {
					cliTool.setStubDirectory(parsedArguments.getOptionValue("ds"));
				}

				// A file path, that points to a file, that contains the license text.
				// -l --license license text in generated files
				if(parsedArguments.hasOption("l")) {
					cliTool.setLicenseText(parsedArguments.getOptionValue("l"));
				}
				// print out generated files
				if(parsedArguments.hasOption("pf")) {
					cliTool.listGeneratedFiles();
				}
				// Switch off validation
				if(parsedArguments.hasOption("nv")) {
					cliTool.disableValidation();
				}
                // Treat validation warnings as errors
                if(parsedArguments.hasOption("ve")) {
                    cliTool.enableValidationWarningsAsErrors();
                }
				// Don't generate code for included types and interfaces
				if(parsedArguments.hasOption("wod")) {
					cliTool.noCodeforDependencies();
				}
				// Don't generate synchronous calls
				if(parsedArguments.hasOption("nsc")) {
					cliTool.disableSyncCalls();
				}
				// Switch off code generation at all
				if(parsedArguments.hasOption("ng")) {
					cliTool.disableCodeGeneration();
				}

				// finally invoke the generator.
                return cliTool.generateSomeIp(files);
            }
            else
            {
                System.out.println("The file extension should be ." + FILE_EXTENSION_FDEPL);
            }
        }
        else
        {
            System.out.println("A *.fdepl file was not specified !");
        }
        return 0;
    }
}
