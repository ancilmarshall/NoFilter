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

+ (void)addImage:(UIImage*)image context:(NSManagedObjectContext*)context;
{
        
    NFPImageData* imageData =
    [NSEntityDescription
     insertNewObjectForEntityForName:NSStringFromClass([self class])
     inManagedObjectContext:context];
    
    imageData.image = image;
    imageData.thumbnail =  nil;
    imageData.hasThumbnail = NO;
    imageData.dateCreated = [NSDate date];
    
    NSError* error;
    if (![context save:&error]){
        NSLog(@"Unable to insert new entity: %@",[error localizedDescription]);
    }
    
    
}

#pragma mark - Simplified accessors

-(BOOL)hasThumbnail;
{
    return [self.hasThumbnailNumber boolValue];
}

-(void)setHasThumbnail:(BOOL)value;
{
    self.hasThumbnailNumber = @(value);
}

-(UIImage*)image;
{
    return [UIImage imageWithData:self.imageData];
}

-(void)setImage:(UIImage*)image;
{
    self.imageData = UIImageJPEGRepresentation(image, 1.0);
}

-(UIImage*)thumbnail;
{
    return [UIImage imageWithData:self.thumbnailData];
}

-(void)setThumbnail:(UIImage*)image;
{
    //Create an empty NSData to avoid the error when saving a nil property
    // to the persistent store
    if (image==nil)
      self.thumbnailData = [NSData new];
    else
        self.thumbnailData = UIImageJPEGRepresentation(image, 1.0);
}


@end
