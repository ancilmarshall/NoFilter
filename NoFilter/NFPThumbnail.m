//
//  NFPImageItem.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

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
    }
    return self;
}
@end
