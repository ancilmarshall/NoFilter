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

//@interface NFPImageData (NFPExtension)()
//@property (nonatomic,strong) UIImage* newImage;
//@property (nonatomic,strong) NSUInteger index;
//@end

@implementation NFPImageData (NFPExtension)

+ (NFPImageData*)initWithImage:(UIImage*)image atCollectionIndex:(NSUInteger)index;
{

    //Cache data
//    self.newImage = image;
//    self.newIndex = index;
    
    NFPImageManagedObjectContext* moc = [[AppDelegate delegate] managedObjectContext];
    NFPImageData* imageData =
        [NSEntityDescription
         insertNewObjectForEntityForName:NSStringFromClass([self class])
         inManagedObjectContext:moc];
    
    imageData.image = image;
    imageData.index = @(index);
    imageData.thumbnail = nil;
    imageData.hasThumbnail = @(NO);
    imageData.dateCreated = [NSDate date];
    
    return imageData;
}


//- (void) awakeFromInsert;
//{
//    [super awakeFromInsert];
//    self.image = self.newImage;
//    self.index = self.newIndex;
//    self.thumbnail = nil;
//    self.hasThumbnail = NO;
//}




@end
