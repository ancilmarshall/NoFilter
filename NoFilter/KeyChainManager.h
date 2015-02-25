//
//  KeyChainManager.h
//  UW_HW7_Ancil
//
//  Created by Ancil on 12/18/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface KeyChainManager : NSObject

+ (instancetype)sharedInstance; // for the singleton pattern

-(OSStatus)addUsername:(NSString*)username password:(NSString*)password;
-(OSStatus)updateUsername:(NSString*)username password:(NSString*)password;
-(BOOL)containsUsername:(NSString*)username;
-(NSString*)passwordForUsername:(NSString*)username;

@end

