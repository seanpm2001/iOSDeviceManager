//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Feb 20 2016 22:04:40).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2015 by Steve Nygard.
//

#import <objc/NSObject.h>

@interface MDKRestorableBuild : NSObject
{
    struct __AMRestorableBuild *mRestorableBuildRef;
}

- (id)restoreBundleURLForBoardConfig:(id)arg1 variantName:(id)arg2 error:(id *)arg3;
- (id)supportedBoardConfigsAndReturnError:(id *)arg1;
- (id)supportedVariantsForBoardConfig:(id)arg1 error:(id *)arg2;
- (void)dealloc;
- (id)initWithURL:(id)arg1 error:(id *)arg2;
- (id)initWithRestorableBuildRef:(struct __AMRestorableBuild *)arg1;

@end

