//
//  NFPImageItem.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFPThumbnail.h"

@implementation NFPThumbnail

-(instancetype) initWithRawImage:(UIImage*)image
               atCollectionIndex:(NSUInteger)index;
{
    self = [super init];
    if (self) {
        _rawImage = image;
        _index = index;
        _thumbnailImage = nil;
        _hasThumbnail = NO;
        _observer = nil;
        _keyPath = nil;
    }
    return self;
}

-(void)dealloc;
{
    NSAssert(self.observer != nil,
             @"Observer not set when attempting to deallocate thumbnail");
    NSAssert(self.keyPath != nil,
             @"KVO KeyPath not set when attempting to deallocate thumbnail");
    [self removeObserver:self.observer forKeyPath:self.keyPath];
}

@end
