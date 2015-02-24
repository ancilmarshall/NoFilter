//
//  KeyChainManager.h
//  UW_HW7_Ancil
//
//  Created by Ancil on 12/18/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol KeyChainManagerDelegate;

@interface KeyChainManager : NSObject
@property (nonatomic,weak) id<KeyChainManagerDelegate> delegate;

+ (instancetype)sharedInstance; // for the singleton pattern

-(OSStatus)addHostname:(NSString*)hostname
              username:(NSString*)username
              password:(NSString*)password;

-(OSStatus)updateHostname:(NSString*)hostname
                 username:(NSString*)username
                 password:(NSString*)password;

-(NSInteger)count;
-(BOOL)containsHostname:(NSString*)hostname;
-(NSString*)hostnameForIndex:(NSInteger)index;
-(NSString*)usernameForIndex:(NSInteger)index;
-(NSString*)passwordForIndex:(NSInteger)index;

-(NSString*)usernameForHostname:(NSString*)hostname;
-(NSString*)passwordForHostname:(NSString*)hostname;
@end

//define a delegate protocol to communicate with delegate when there are changes to manager
@protocol KeyChainManagerDelegate <NSObject>
-(void)keyChainManagerDidAddItem;
-(void)keyChainManagerDidUpdateItem;
@end