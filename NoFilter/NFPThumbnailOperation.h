//
//  NFPThumbnailOperation.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "NFPThumbnail.h"

@interface NFPThumbnailOperation : NSOperation
-(instancetype)initWithNFPThumbnail:(NFPThumbnail*) thumbnail  NS_DESIGNATED_INITIALIZER;
@end
