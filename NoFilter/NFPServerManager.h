//
//  NFPServerManager.h
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol NFPServerManagerProtocol;


@interface NFPServerManager : NSObject

@property (nonatomic,weak) id<NFPServerManagerProtocol> delegate;
+(instancetype) sharedInstance;
-(void)logonToServer;
-(void)uploadImage:(UIImage*)image;
@end

@protocol NFPServerManagerProtocol <NSObject>

-(void)NFPServerManagerSessionDidCompleteWithSuccess:(BOOL)success msg:(NSString*)msg;

@end
