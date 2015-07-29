package org.genivi.commonapi.someip.cli;

import java.util.List;

import org.apache.commons.cli.CommandLine;
import org.genivi.commonapi.console.AbstractCommandLineHandler;
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

        String[] args = parsedArguments.getArgs();
        if (args.length > 0 && args[0] != null)
        {
            String file = args[0];
            if (file.endsWith(FILE_EXTENSION_FDEPL) || file.endsWith(FILE_EXTENSION_FIDL))
            {
				// handle command line options
				
				// -ll --loglevel quiet or verbose
				if(parsedArguments.hasOption("ll")) {
					cliTool.setLogLevel(parsedArguments.getOptionValue("ll"));
				}
				
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
					cliTool.setStubtDirectory(parsedArguments.getOptionValue("ds"));
				}

				// A file path, that points to a file, that contains the license text.
				// -l --license license text in generated files
				if(parsedArguments.hasOption("l")) {
					cliTool.setLicenseText(parsedArguments.getOptionValue("l"));
				}

                // finally invoke the generator.
                // the remaining arguments are assumed to be files !
                @SuppressWarnings("unchecked")
                List<String> remainingArgs = parsedArguments.getArgList();
                cliTool.generateSomeIp(remainingArgs);
            }
            else
            {
                System.out.println("The file extension should be ." + FILE_EXTENSION_FIDL + " or ." + FILE_EXTENSION_FDEPL);
            }
        }
        else
        {
            System.out.println("A *.fidl or *.fdepl file was not specified !");
        }
        return 0;
    }
}
