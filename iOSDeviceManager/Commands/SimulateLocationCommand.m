
#import "SimulateLocationCommand.h"
#import "ConsoleWriter.h"

static NSString *const LOCATION_FLAG = @"-l";

@implementation SimulateLocationCommand
+ (NSString *)name {
    return @"set_location";
}

+ (iOSReturnStatusCode)execute:(NSDictionary *)args {
    NSString *ll = args[LOCATION_FLAG];
    NSArray *latlng = [ll componentsSeparatedByString:@","];
    if (latlng.count != 2) {
        ConsoleWriteErr(@"Expected lat,lng: Got %@", ll);
        return iOSReturnStatusCodeInvalidArguments;
    }
    return [Device setLocation:args[DEVICE_ID_FLAG] ?: args[DEVICE_ID_ARGNAME] ?: [Device defaultDeviceID]
                           lat:[latlng[0] doubleValue]
                           lng:[latlng[1] doubleValue]];
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
        [options addObject:[CommandOption withShortFlag:LOCATION_FLAG
                                               longFlag:@"--location"
                                             optionName:@"lat,lng"
                                                   info:@"latitude and longitude separated by a single comma"
                                               required:YES
                                             defaultVal:nil]];
    });
    return options;
}
@end
