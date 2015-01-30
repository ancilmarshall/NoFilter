//
//  NFPImageData.h
//  NoFilter
//
//  Created by Ancil on 1/30/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface NFPImageData : NSManagedObject

@property (nonatomic, retain) id image;
@property (nonatomic, retain) id thumbnail;
@property (nonatomic, retain) NSNumber * hasThumbnail;
@property (nonatomic, retain) NSNumber * index;
@property (nonatomic, retain) NSDate * dateCreated;

@end
