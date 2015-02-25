//
//  KeyChainManager.m
//  UW_HW7_Ancil
//
//  Created by Ancil on 12/18/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import "KeyChainManager.h"

// Use a kSecAttrLabel to specify all secure items  with this application
static NSString* const kPasswordManagerAppLabel = @"NoFilterPasswordManagerApp";


#pragma mark - KeyChainManager

@interface KeyChainManager()
@property (nonatomic,strong) NSMutableArray* usernames;
@end

@implementation KeyChainManager

#pragma mark - Initialization
/*
 * Singleton method to share one instance across the application
 */
+ (instancetype)sharedInstance;
{
    static id sharedInstance = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [self new];
    });
    
    return sharedInstance;
}

/*
 * Override the instance init method. Setups up the  member keyChainItem array
 */
-(instancetype)init
{
    self = [super init];
    if (self){
        _usernames = [NSMutableArray new];
        [self getAllkeyChainItems];
    }
    return self;
}

/*
 *  Initialize instance by getting all the keychain items for this application
 *  and setting the member data keyChainItems array which is used to quick lookups
 */
-(void)getAllkeyChainItems;
{
    NSDictionary* query = @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                             (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                             (__bridge id)kSecMatchLimit : (__bridge id)kSecMatchLimitAll,
                             (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue};
    
    CFArrayRef result = NULL;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef) query, (CFTypeRef*)&result);
    
    if (result != NULL){
        NSArray* resultsArray = (__bridge NSArray*)result;
        
        // Use the block enumeration, just for fun and practice
        [resultsArray enumerateObjectsUsingBlock:^(NSDictionary* pair, NSUInteger idx, BOOL *stop) {
            //only search for the kSecAttrAccount attribute in the returned
            // dictionary which stores the username
            NSString* username =pair[(__bridge id)kSecAttrAccount];
            [self.usernames addObject:username];
        }];
        
    }
    
    // Note: errSecItemNotFound only happens the there are actually no items stored
    // in the keychain, so we can ignore this error since we know we have not yet
    // put any items into the keychain
    if ( status != errSecSuccess && status !=errSecItemNotFound)
    {
        [self KeyChainAssert:@"Error getting all KeyChainManager items" status:status];
    }
}

#pragma mark - Accessors and Modifiers

-(OSStatus)addUsername:(NSString*)username password:(NSString*)password;
{
    
    //perform secure keychain operations here
    // Add two attributes and one value data
    NSDictionary* attributes = @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                                  (__bridge id)kSecAttrAccount : username,
                                  (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                                  (__bridge id)kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding ]};
    
    OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if ( status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error adding to KeyChainManager" status:status];
    }
    
    [self.usernames addObject:username];
    return status;
}

-(OSStatus)updateUsername:(NSString*)username password:(NSString*)password;
{
    NSUInteger index = [self.usernames indexOfObject:username];
    [self.usernames replaceObjectAtIndex:index withObject:username];
    
    //set up query to match the hostname and kCommonPasswordManagerAppLabel string
    NSDictionary* query = @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                             (__bridge id)kSecAttrAccount : username,
                             (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel};
    
    NSDictionary* attributes = @{ (__bridge id)kSecAttrAccount : username,
                                  (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                                  (__bridge id)kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding ]};
    
    OSStatus status =  SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);

    if ( status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error updating KeyChainManager" status:status];
    }

    return status;
}


-(NSString*)passwordForUsername:(NSString *)username;
{
    NSAssert([self containsUsername:username],@"Username does not exist in KeyChainManager");
    
    NSString* password;

    //set up query to match the username and kCommonPasswordManagerAppLabel string
    // and return the secure data
    NSDictionary* query =  @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                              (__bridge id)kSecAttrAccount : username ,
                              (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                              (__bridge id)kSecReturnData : (__bridge id)kCFBooleanTrue};
    
    CFTypeRef result = NULL;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error retrieving password" status:status];
    }
    if (result != NULL){
        NSData* resultData = (__bridge NSData*)result;
        password = [[NSString alloc] initWithData:resultData encoding:NSUTF8StringEncoding];
    }
    
    return password;
}


-(BOOL)containsUsername:(NSString*)username;
{
    return [self.usernames containsObject:username];
}

-(void)KeyChainAssert:(NSString*)msg status:(OSStatus)status
{
    NSString* description = [msg stringByAppendingString:
                             [NSString stringWithFormat:@" (Status=%tu)",(NSInteger)status]];
    NSAssert(NO,description);
}

@end
