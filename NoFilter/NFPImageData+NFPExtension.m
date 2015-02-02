//
//  NFPImageData+NFPExtension.m
//  NoFilter
//
//  Created by Ancil on 1/29/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//


/*                              NOTE
 Adding this category is a neat trick to add methods to the managed core data
 model object and keep these methods available when this model attributes, etc
 are changed and re-compiled
 */

#import "AppDelegate.h"
#import "NFPImageManagedObjectContext.h"
#import "NFPImageData+NFPExtension.h"

@implementation NFPImageData (NFPExtension)

+ (NFPImageData*)addImage:(UIImage*)image;
{
    
    NFPImageManagedObjectContext* moc = [[AppDelegate delegate] managedObjectContext];
    NFPImageData* imageData =
        [NSEntityDescription
         insertNewObjectForEntityForName:NSStringFromClass([self class])
         inManagedObjectContext:moc];
    
    imageData.image = image;
    imageData.thumbnail = nil;
    imageData.hasThumbnail = @(NO);
    imageData.dateCreated = [NSDate date];
    
    return imageData;
}

@end
