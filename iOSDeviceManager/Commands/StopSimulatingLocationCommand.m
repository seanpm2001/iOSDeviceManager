
#import "StopSimulatingLocationCommand.h"
#import "PhysicalDevice.h"

@implementation StopSimulatingLocationCommand
+ (NSString *)name {
    return @"stop_simulating_location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    return [PhysicalDevice stopSimulatingLocation:args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: [Device defaultDeviceID]];
}

+ (NSArray <CommandOption *> *)options {
    static NSMutableArray *options;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        options = [NSMutableArray array];
        [options addObject:[CommandOption withShortFlag:DEVICE_ID_FLAG
                                               longFlag:@"--device-id"
                                             optionName:@"device-identifier"
                                                   info:@"iOS Simulator GUIDs"
                                               required:NO
                                             defaultVal:nil]];
    });
    return options;
}
@end
