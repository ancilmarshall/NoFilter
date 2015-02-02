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
@property (nonatomic, retain) NSNumber * hasThumbnail;
@property (nonatomic, retain) id image;
@property (nonatomic, retain) id thumbnail;

@end
