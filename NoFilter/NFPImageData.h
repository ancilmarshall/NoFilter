//
//  NFPImageData.h
//  NoFilter
//
//  Created by Ancil on 2/2/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NFPImageData : NSManagedObject

@property (nonatomic, retain) NSDate * dateCreated;
@property (nonatomic, retain) NSNumber * hasThumbnailNumber;
@property (nonatomic, retain) NSData * imageData;
@property (nonatomic, retain) NSData * thumbnailData;

@end
