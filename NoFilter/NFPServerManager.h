//
//  NFPServerManager.h
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

extern NSString* NFPServerManagerTaskFailedNotification;
extern NSString* NFPServerManagerLoginDidSucceedNotification;

@class NFPImageData;

@interface NFPServerManager : NSObject

@property (nonatomic,assign) BOOL serverConnectionValid;
@property (nonatomic,strong) void(^backgroundDownloadCompletionHandler)();

+(instancetype) sharedInstance;
-(void)logonToServer;
-(void)uploadImage:(NFPImageData*)imageData context:(NSManagedObjectContext*)context;
-(void) getItemList;
-(void)createBackgroundDownloadSessionIfNeeded;
-(void)deleteAllImagesOnServer;

@end

