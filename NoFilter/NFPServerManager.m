//
//  NFPServerManager.m
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPServerManager.h"
#import "KeyChainManager.h"

static NSString* const NFPServerScheme = @"http";
static NSString* const NFPServerPath = @"/api/v1/";
NSString* const NFPServerHost = @"nofilter.pneumaticsystem.com";


@interface NFPServerManager()

@property (nonatomic,strong) NSDictionary* clientPlistDict;
@property (nonatomic,strong) NSString* token;

@end

@implementation NFPServerManager


+(instancetype) sharedInstance;
{
    static NFPServerManager* instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[NFPServerManager alloc] initSingleton];
    });
    return instance;
}

-(instancetype)initSingleton;
{
    self = [super init];
    if (self){
        
        NSURL* clientPlistURL = [[NSBundle mainBundle] URLForResource:@"NoFilterWebApp" withExtension:@"plist"];
        self.clientPlistDict = [NSDictionary dictionaryWithContentsOfURL:clientPlistURL];
        
        [self renewToken];
        
    }
    return self;
}


-(void)renewToken;
{
    NSMutableArray* queryItems = [NSMutableArray new];
    [queryItems addObject:[NSURLQueryItem
                   queryItemWithName:[NFPServerManager serverKeys][@"appKey"]
                   value:self.clientPlistDict[[NFPServerManager serverKeys][@"appKey"]]]];
    
    [queryItems addObject:[NSURLQueryItem
                           queryItemWithName:[NFPServerManager serverKeys][@"appSecret"]
                           value:self.clientPlistDict[[NFPServerManager serverKeys][@"appSecret"]]]];
    
    [queryItems addObject:[NSURLQueryItem
                           queryItemWithName:[NFPServerManager serverKeys][@"username"]
                           value:[[KeyChainManager sharedInstance] usernameForHostname:NFPServerHost]]];
    
    [queryItems addObject:[NSURLQueryItem
                           queryItemWithName:[NFPServerManager serverKeys][@"password"]
                           value:[[KeyChainManager sharedInstance] passwordForHostname:NFPServerHost]]];
    
    
    
    
    NSURLComponents* URLcomponents =
        [self NSURLComponentsFromEndpoint:[NFPServerManager serverEndpoints][@"token"]
                               queryItems:queryItems];
    
    NSURL* url = URLcomponents.URL;
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            if (!error)
            {
                NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                         @"Expected response to be of type NSHTTPURLResponse");
                NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                if (httpResp.statusCode == 200){
                    
                    NSError* jsonError = nil;
                    
                    NSDictionary* jsonResp =
                    [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingAllowFragments
                                                      error:&jsonError];

                    if (!jsonError){
                        if (jsonResp[@"success"]){
                            
                            self.token = jsonResp[@"result"][@"token"];
                            NSLog(@"token is: %@",self.token);
                            
                        } else {
                            NSLog(@"Reponse data reports a failure");
                        }
                        
                    } else {
                        NSLog(@"Error serializing json data in NFPServerManager -renewToken: %@",[jsonError localizedDescription]);
                    }
                } else {
                    NSLog(@"Error reported from NoFilter server during the NFPServerManager -renewToken function request");
                }
                
            } else {
                NSLog(@"Error in NFPServerMangager -renewToken function: %@",
                      [error localizedDescription]);
            }
                
        }];
    
    [task resume];
    
    
    
}

-(NSURLComponents*)NSURLComponentsFromEndpoint:(NSString*)endpoint queryItems:(NSArray*)queryItems;
{
    
    NSURLComponents* components = [[NSURLComponents alloc] init];
    components.scheme = NFPServerScheme;
    components.host = NFPServerHost;
    components.path = [NFPServerPath stringByAppendingString:endpoint];
    components.queryItems = queryItems;
    
    return  components;
    
}

#pragma -mark helper functions
+(NSDictionary*) serverKeys;
{
    NSMutableDictionary* serverKeysDict = [NSMutableDictionary new];
    serverKeysDict[@"appKey"] = @"app_key";
    serverKeysDict[@"appSecret"] = @"app_secret";
    serverKeysDict[@"token"] = @"token";
    serverKeysDict[@"username"] = @"username";
    serverKeysDict[@"password"] = @"password";
    serverKeysDict[@"itemID"] = @"item_id";
    serverKeysDict[@"file"] = @"file";
    serverKeysDict[@"appName"] = @"app_name";
    serverKeysDict[@"appID"] = @"app_id";
    return [NSDictionary dictionaryWithDictionary:serverKeysDict];
}

+(NSDictionary*) serverEndpoints;
{
    
    NSMutableDictionary* serverEndpointsDict = [NSMutableDictionary new];
    serverEndpointsDict[@"token"] = @"auth/token";
    serverEndpointsDict[@"validateToken"] = @"auth/validate_token";
    serverEndpointsDict[@"listItems"] = @"item/list";
    serverEndpointsDict[@"getItems"] = @"item/get";
    serverEndpointsDict[@"getRawItems"] = @"item/get_raw";
    serverEndpointsDict[@"createItem"] = @"item/create";
    serverEndpointsDict[@"deleteItem"] = @"item/delete";
    serverEndpointsDict[@"listUsers"] = @"user/list";
    serverEndpointsDict[@"createUser"] = @"user/create";
    serverEndpointsDict[@"deleteUser"] = @"user/delete";
    serverEndpointsDict[@"listApps"] = @"app/list";
    serverEndpointsDict[@"createApps"] = @"app/create";
    serverEndpointsDict[@"deleteApp"] = @"app/delete";
    serverEndpointsDict[@"resetAppSecret"] = @"app/reset_secret";
    
    return [NSDictionary dictionaryWithDictionary:serverEndpointsDict];
}


@end
