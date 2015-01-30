//
//  NFPImageManagedObjectContext.h
//  NoFilter
//
//  Created by Ancil on 1/30/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface NFPImageManagedObjectContext : NSManagedObjectContext
+ (instancetype)contextForStoreAtURL:(NSURL *)storeURL;
@end
