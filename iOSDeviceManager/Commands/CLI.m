
#import <CocoaLumberjack/CocoaLumberjack.h>
#import "iOSDeviceManagementCommand.h"
#import "ConsoleWriter.h"
#import <objc/runtime.h>
#import "ShellRunner.h"
#import "JSONUtils.h"
#import "Command.h"
#import "CLI.h"
#import "DeviceUtils.h"
#import "IsInstalledCommand.h"
#import "AppInfoCommand.h"
#import "LaunchSimulatorCommand.h"
#import "EraseSimulatorCommand.h"

static const DDLogLevel ddLogLevel = DDLogLevelDebug;

@implementation CLI

static NSMutableDictionary <NSString *, Class> *commandClasses;

+ (void)load {
    unsigned int outCount;
    Class *classes = objc_copyClassList(&outCount);
    commandClasses = [NSMutableDictionary dictionaryWithCapacity:outCount];
    for (int i = 0; i < outCount; i++) {
        Class c = classes[i];
        if (class_conformsToProtocol(c, @protocol(iOSDeviceManagementCommand))) {
            if (![c isSubclassOfClass:[Command class]]) {
                @throw [NSException exceptionWithName:@"ProgrammerErrorException"
                                               reason:@"Commands should subclass the Command class"
                                             userInfo:nil];
            }
            if ([c class] == [Command class]) {
                continue;
            }
            if ([c name]) {
                commandClasses[[c name]] = c;
            }
        }
    }
    free(classes);
}

+ (void)printUsage {
    NSString *program = [[NSProcessInfo processInfo].arguments[0]
        lastPathComponent];
    ConsoleWrite(@"USAGE: %@ [command] [flags]\n", program);

    ConsoleWrite(@"To see command-specific help:");
    ConsoleWrite(@"$ %@ [command]\n", program);

    NSSortDescriptor *sorter;
    sorter = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES];
    NSArray *sorted;
    sorted = [[commandClasses allValues] sortedArrayUsingDescriptors:@[sorter]];

    for (Class<iOSDeviceManagementCommand> c in sorted) {
        ConsoleWrite(@"\t%@", [c name]);
    }
    ConsoleWrite(@"\n");
}

/*
 For parsing args - positional values may be used (regardless of order) and their
 corresponding property is determined by `positionalArgShortFlag`. Using redundant
 args will result in iOSReturnStatusCodeInvalidArguments response.
*/
+ (NSDictionary<NSString *,
                NSString *> *)parseArgs:(NSArray <NSString *> *)args
                             forCommand:(Class<iOSDeviceManagementCommand>)command
                               exitCode:(int *)exitCode {

    if (args.count == 0) {
        if (![[command name] isEqualToString:@"kill-simulator"]) {
            [command printUsage];
            *exitCode = iOSReturnStatusCodeEverythingOkay;
            return @{};
        }
    }

    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    NSUInteger positionalArgCount = 0;

    for (int i = 0; i < args.count; i++) {
        CommandOption *op = [command optionForFlag:args[i]];
        // This is true when the arg provided isn't a recognized flag or isn't a flag
        if (op == nil) {
            CommandOption *positionalOption;
            if ([[command name] isEqualToString:[IsInstalledCommand name]]
                || [[command name] isEqualToString:[AppInfoCommand name]]) {
                // IsInstalledCommand and AppInfoCommand accepts either bundle
                // id OR app path as a positional (0) arg
                // The determine the option based on the context
                positionalOption = [command optionForAppPathOrBundleID:args[i]];
            } else {
                positionalOption = [command optionForPosition:positionalArgCount];
            }
            if (positionalOption) {
                values[positionalOption.optionName] = args[i];
                positionalArgCount += 1;
                continue;
            } else {
                ConsoleWriteErr(@"Unrecognized flag or unsupported argument: %s\n",
                                [args[i] cStringUsingEncoding:NSUTF8StringEncoding]);
                [self printUsage];
                *exitCode = iOSReturnStatusCodeUnrecognizedFlag;
                return nil;
            }
        }
        if (args.count <= i + 1 && op.requiresArgument) {
            ConsoleWriteErr(@"No value provided for %@\n", args[i]);
            [command printUsage];
            *exitCode = iOSReturnStatusCodeMissingArguments;
            return nil;
        }
        if ([values objectForKey:op.optionName]) {
            ConsoleWriteErr(@"Multiple arguments detected for %@", op.optionName);
            [command printUsage];
            *exitCode = iOSReturnStatusCodeInvalidArguments;
            return nil;
        }
        if (op.requiresArgument) {
            values[op.optionName] = args[i+1];
            i++;
        } else {
            values[op.optionName] = @YES;
        }
    }

    *exitCode = iOSReturnStatusCodeEverythingOkay;
    return values;
}

+ (iOSReturnStatusCode)process:(NSArray<NSString *> *)args {
    if (args.count <= 1) {
        [self printUsage];
        return iOSReturnStatusCodeEverythingOkay;
    } else {
        NSString *commandName = [args[1] lowercaseString];
        Class <iOSDeviceManagementCommand> command = commandClasses[commandName];

        if (command) {
            //Ensure args can be parsed correctly
            NSArray *cmdArgs = args.count == 2 ? @[] : [args subarrayWithRange:NSMakeRange(2, args.count - 2)];
            int ec;
            NSDictionary *parsedArgs = [self parseArgs:cmdArgs
                                            forCommand:command
                                              exitCode:&ec];
            if (ec != iOSReturnStatusCodeEverythingOkay) {
                return ec;
            }

            //If the user specified they want help, just print help and exit.
            if ([parsedArgs hasKey:HELP_SHORT_FLAG] ||
                [parsedArgs hasKey:HELP_LONG_FLAG]) {
                [command printUsage];
                return iOSReturnStatusCodeEverythingOkay;
            }

            //Ensure all required args are present
            for (CommandOption *opt in [command options]) {
                if (opt.required && ![parsedArgs.allKeys containsObject:opt.optionName]) {
                    printf("Missing required argument '%s'\n",
                           [opt.optionName cStringUsingEncoding:NSUTF8StringEncoding]);
                    [command printUsage];

                    if ([opt.optionName isEqualToString:DEVICE_ID_OPTION_NAME]) {
                        NSString *physicalDeviceID =
                            [DeviceUtils defaultPhysicalDeviceIDEnsuringOnlyOneAttached:NO];
                        NSArray *blackListedCommands = @[[LaunchSimulatorCommand name], [EraseSimulatorCommand name]];
                        if (physicalDeviceID && ![blackListedCommands containsObject:[command name]]) {
                            [ConsoleWriter
                             write:@"\n Suggested deviceID from connected device: %@", physicalDeviceID];
                        } else {
                            NSString *simulatorID = [DeviceUtils defaultSimulatorID];
                            [ConsoleWriter
                             write:@"\n Suggested deviceID for simulator: %@", simulatorID];
                        }
                    }
                    return iOSReturnStatusCodeMissingArguments;
                }
            }

            //If exit non-0, print usage.
            iOSReturnStatusCode ret = [command execute:parsedArgs];

            DDLogVerbose(@"%@ ==> %@ %@", [command name], @(ret), parsedArgs);

            if (ret != iOSReturnStatusCodeEverythingOkay &&
                ret != iOSReturnStatusCodeFalse) {
                [command printUsage];
            }
            return ret;
        } else {
            [ConsoleWriter err:@"Unrecognized command: %@", commandName];
            [self printUsage];
            return iOSReturnStatusCodeUnrecognizedCommand;
        }
    }
}

@end
