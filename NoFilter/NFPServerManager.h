//
//  NFPServerManager.h
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString* const NFPServerHost;
@protocol NFPServerManagerProtocol;


@interface NFPServerManager : NSObject

@property (nonatomic,weak) id<NFPServerManagerProtocol> delegate;

+(instancetype) sharedInstance;
-(void)uploadImage:(UIImage*)image;

@end

@protocol NFPServerManagerProtocol <NSObject>

-(void)tokenReceivedFromServer;

@end
