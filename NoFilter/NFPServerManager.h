//
//  NFPServerManager.h
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFPServerManager : NSObject
+(instancetype) sharedInstance;
extern NSString* const NFPServerHost;
@end
