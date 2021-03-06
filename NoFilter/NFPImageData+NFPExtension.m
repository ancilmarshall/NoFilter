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
#import "NFPServerManager.h"

#if 0 && defined(DEBUG)
#define IMAGE_DATA_LOG(format, ...) NSLog(@"NFPImageData: " format, ## __VA_ARGS__)
#else
#define IMAGE_DATA_LOG(format, ...)
#endif

@implementation NFPImageData (NFPExtension)

+ (NFPImageData*)addImage:(UIImage*)image context:(NSManagedObjectContext*)context;
{
    NFPImageData* imageData =  [self addImage:image context:context withID:0];
    [[NFPServerManager sharedInstance] uploadImage:imageData context:context];

    return imageData;
}

+ (NFPImageData*)addImage:(UIImage*)image context:(NSManagedObjectContext*)context withID:(NSUInteger)imageID;
{
    IMAGE_DATA_LOG(@"Inserting image with ID: %tu",imageID);
    
    NFPImageData* imageData =
    [NSEntityDescription
     insertNewObjectForEntityForName:NSStringFromClass([self class])
     inManagedObjectContext:context];
    
    imageData.image = image;
    imageData.thumbnail =  nil;
    imageData.hasThumbnail = NO;
    imageData.dateCreated = [NSDate date];
    imageData.imageID = imageID;
    
    [context performBlock:^{
        NSError* error;
        if (![context save:&error]){
            NSLog(@"\nUnable to insert new entity: %@\nwith error error:%@",imageData,[error localizedDescription]);
        }
    }];
    
    return imageData;
    
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
    //Creates a new instance of UIImage
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

-(void)setImageID:(NSUInteger)imageID;
{
    self.id = @(imageID);
}

-(NSUInteger)imageID;
{
    return [self.id unsignedIntegerValue];
}

/*
 * Override description to provide easily readable class print output
 */
-(NSString*)description;
{
    return [NSString stringWithFormat:
        @"\nImage Details...\n\tID: %tu\n\tImage: %@\n\tThumbnail: %@",
            self.imageID,self.image,self.thumbnail];
}


@end
