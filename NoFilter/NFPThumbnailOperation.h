//
//  NFPThumbnailOperation.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NFPImageData.h"

@interface NFPThumbnailOperation : NSOperation
-(instancetype)initWithNFPImageData:(NFPImageData*)imageData
                            context:(NSManagedObjectContext*)context NS_DESIGNATED_INITIALIZER;
@end
