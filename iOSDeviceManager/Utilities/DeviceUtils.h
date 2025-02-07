
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT license.

#import <Foundation/Foundation.h>
#import <FBSimulatorControl/FBSimulatorControl.h>
#import <FBDeviceControl/FBDeviceControl.h>
#import <CoreSimulator/SimDevice.h>
#import <CoreSimulator/SimDeviceBootInfo.h>

@interface DeviceUtils : NSObject
+ (BOOL)isDeviceID:(NSString *)uuid;
+ (BOOL)isSimulatorID:(NSString *)uuid;
+ (NSString *)findDeviceIDByName:(NSString *)name;
+ (NSString *)defaultSimulator;
+ (NSString *)defaultSimulatorID;
+ (NSString *)defaultPhysicalDeviceIDEnsuringOnlyOneAttached:(BOOL)shouldThrow;
+ (NSString *)defaultDeviceID;
+ (NSArray<FBDevice *> *)availableDevices;
+ (NSArray<FBSimulator *> *)availableSimulators;
+ (FBFuture<FBDeviceSet *> *)deviceSet:(id<FBControlCoreLogger>)logger ecidFilter:(NSString *)ecidFilter;
+ (FBDeviceSet *)deviceSet;
@end
