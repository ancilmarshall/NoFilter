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

#pragma mark - Private KeychainItem object, used to store the hostname

@interface KeyChainItem : NSObject

@property (nonatomic,strong) NSString* hostname;

-(instancetype)initWithHostname:(NSString*)hostname NS_DESIGNATED_INITIALIZER;
@end

@implementation KeyChainItem
-(instancetype)initWithHostname:(NSString*)hostname;
{
    if (self = [super init]){
        _hostname = hostname;
    }
    return self;
}

//overload the isEqual so that we can perform searches in an array of keyChainItems
//only match the hostnames for equality
-(BOOL)isEqual:(KeyChainItem*)other
{
    return [self.hostname isEqual:other.hostname];
    
}
@end

#pragma mark - KeyChainManager

@interface KeyChainManager()
@property (nonatomic,strong) NSMutableArray* keyChainItems; // used to keep quickly
    //keep track of items without need to search and use the KeyChain Services API
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
        _keyChainItems = [NSMutableArray new];
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
        
//        for (NSDictionary* pair in resultsArray)
//        {
//            //only search for the kSecAttrServer attribute in the returned
//            // dictionary which stores the hostname
//            NSString* hostname =pair[(__bridge id)kSecAttrServer];
//            KeyChainItem* item = [[KeyChainItem alloc] initWithHostname:hostname];
//            [self.keyChainItems addObject:item];
//        }
        
        // Try also using the block enumeration, just for fun
        [resultsArray enumerateObjectsUsingBlock:^(NSDictionary* pair, NSUInteger idx, BOOL *stop) {
            //only search for the kSecAttrServer attribute in the returned
            // dictionary which stores the hostname
            NSString* hostname =pair[(__bridge id)kSecAttrServer];
            KeyChainItem* item = [[KeyChainItem alloc] initWithHostname:hostname];
            [self.keyChainItems addObject:item];
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

-(OSStatus)addHostname:(NSString*)hostname username:(NSString*)username password:(NSString*)password;
{
    KeyChainItem* item = [[KeyChainItem alloc] initWithHostname:hostname];
    [self.keyChainItems addObject:item];
    
    //perform secure keychain operations here
    // Add three attributes and one value data
    NSDictionary* attributes = @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                                  (__bridge id)kSecAttrServer : hostname,
                                  (__bridge id)kSecAttrAccount : username,
                                  (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                                  (__bridge id)kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding ]};
    
    OSStatus status =  SecItemAdd((__bridge CFDictionaryRef)attributes, NULL);
    if ( status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error adding to KeyChainManager" status:status];
    }
    
    //notify the delegate
    [self.delegate keyChainManagerDidAddItem];
    
    return status;
}

-(OSStatus)updateHostname:(NSString*)hostname username:(NSString*)username password:(NSString*)password;
{
    KeyChainItem* newItem = [[KeyChainItem alloc] initWithHostname:hostname];
    NSUInteger index = [self.keyChainItems indexOfObject:newItem];
    [self.keyChainItems replaceObjectAtIndex:index withObject:newItem];
    
    //set up query to match the hostname and kCommonPasswordManagerAppLabel string
    NSDictionary* query = @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                             (__bridge id)kSecAttrServer : hostname,
                             (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel};
    
    NSDictionary* attributes = @{ (__bridge id)kSecAttrAccount : username,
                                  (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                                  (__bridge id)kSecValueData : [password dataUsingEncoding:NSUTF8StringEncoding ]};
    
    OSStatus status =  SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)attributes);

    if ( status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error updating KeyChainManager" status:status];
    }

    //notify the delegate that changes were made to the manager
    [self.delegate keyChainManagerDidUpdateItem];

    return status;
}


-(NSString*)hostnameForIndex:(NSInteger)index;
{
    return [[self.keyChainItems objectAtIndex:index] hostname];
}

-(NSString*)usernameForIndex:(NSInteger)index;
{
    NSString* hostname = [self hostnameForIndex:index];
    return [self usernameForHostname:hostname];
}

-(NSString*)usernameForHostname:(NSString*)hostname;
{
    
    NSString* username;
    
    //set up query to match the hostname and kCommonPasswordManagerAppLabel string and
    //return the attributes (clear text data)
    NSDictionary* query =  @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                              (__bridge id)kSecAttrServer : hostname ,
                              (__bridge id)kSecAttrLabel : kPasswordManagerAppLabel,
                              (__bridge id)kSecReturnAttributes : (__bridge id)kCFBooleanTrue};
    
    CFTypeRef result = NULL;
    
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    
    if (result !=NULL){
        NSDictionary* resultDictionary = (__bridge NSDictionary*)result;
        username = resultDictionary[(__bridge id)kSecAttrAccount];
    }
    if ( status != errSecSuccess)
    {
        [self KeyChainAssert:@"Error getting username" status:status];
    }
    
    return username;
}

-(NSString*)passwordForIndex:(NSInteger)index;
{
    NSString* hostname = [self hostnameForIndex:index];
    return [self passwordForHostname:hostname];
}

-(NSString*)passwordForHostname:(NSString *)hostname;
{
    NSString* password;
    
    //set up query to match the hostname and kCommonPasswordManagerAppLabel string
    // and return the secure data
    NSDictionary* query =  @{ (__bridge id)kSecClass : (__bridge id)kSecClassInternetPassword,
                              (__bridge id)kSecAttrServer : hostname ,
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


#pragma mark - Helpers

-(NSInteger)count;
{
    return [self.keyChainItems count];
}

-(BOOL)containsHostname:(NSString*)hostname;
{
    KeyChainItem* item = [[KeyChainItem alloc] initWithHostname:hostname];
    return [self.keyChainItems containsObject:item];
}

-(void)KeyChainAssert:(NSString*)msg status:(OSStatus)status
{
    NSString* description = [msg stringByAppendingString:
                             [NSString stringWithFormat:@" (Status=%tu)",(NSInteger)status]];
    NSAssert(NO,description);
}

@end
