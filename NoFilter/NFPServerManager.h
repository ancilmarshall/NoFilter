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
@class NFPImageData;

@interface NFPServerManager : NSObject

@property (nonatomic,weak) id<NFPServerManagerProtocol> delegate;
@property (nonatomic,strong) void(^backgroundDownloadCompletionHandler)();

+(instancetype) sharedInstance;
-(void)logonToServer;
-(void)uploadImage:(NFPImageData*)imageData context:(NSManagedObjectContext*)context;
-(void) getItemList;
-(void)createBackgroundDownloadSessionIfNeeded;

@end

@protocol NFPServerManagerProtocol <NSObject>
//TODO: Why use a delegate when I could display the message in the manager
// and return a bool if things were successful
-(void)NFPServerManagerTaskFailedWithErrorMessage:(NSString*)errorMsg;
-(void)NFPServerManagerDidLoginSuccessfully;
@end
