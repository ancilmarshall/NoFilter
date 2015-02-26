//
//  NFPServerManager.m
//  NoFilter
//
//  Created by Ancil on 2/23/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPServerManager.h"
#import "KeyChainManager.h"
#import "NSData+NFExtensions.h"
#import "NFPLoginViewController.h"

static NSString* const NFPServerScheme = @"http";
static NSString* const NFPServerPath = @"/api/v1/";
static NSString* const NFPServerHost = @"nofilter.pneumaticsystem.com";

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
    }
    return self;
}

/*
 * Get a token from the server and cache the results
 */
-(void)logonToServer;
{
    // Setup the necessary URL query items to pass to the server endpoint for getting token
    NSMutableArray* queryItems = [NSMutableArray new];
    [queryItems addObject:[NSURLQueryItem
       queryItemWithName:[NFPServerManager serverKeys][@"appKey"]
       value:self.clientPlistDict[[NFPServerManager serverKeys][@"appKey"]]]];
    
    [queryItems addObject:[NSURLQueryItem
       queryItemWithName:[NFPServerManager serverKeys][@"appSecret"]
       value:self.clientPlistDict[[NFPServerManager serverKeys][@"appSecret"]]]];
    
    // Always get username from the Standard User Defaults which should be set before
    NSString* username = [[NSUserDefaults standardUserDefaults]
                          valueForKey:kUserDefaultUsername];
    
    [queryItems addObject:[NSURLQueryItem
       queryItemWithName:[NFPServerManager serverKeys][@"username"]
       value:username]];
    
    [queryItems addObject:[NSURLQueryItem
       queryItemWithName:[NFPServerManager serverKeys][@"password"]
       value:[[KeyChainManager sharedInstance] passwordForUsername:username]]];

    // Call helper function to build URL component from host, server enpoint and query items
    NSURLComponents* URLcomponents =
        [self NSURLComponentsFromEndpoint:[NFPServerManager serverEndpoints][@"getToken"]
                               queryItems:queryItems];
    
    NSURL* url = URLcomponents.URL;
    
    // Configure the NSURLSession
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    // Call NSRULSession task and implement its completion handler
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            
            if (!error)
            {
                NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                         @"Expected response to be of type NSHTTPURLResponse");
                NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                
                //Verify http response returns 'ok' i.e. status code 200
                if (httpResp.statusCode == 200){
                    
                    // Parse returned JSON data
                    NSError* jsonError = nil;
                    NSDictionary* jsonResp =
                    [NSJSONSerialization JSONObjectWithData:data
                                                    options:NSJSONReadingAllowFragments
                                                      error:&jsonError];

                    if (!jsonError){
                        //Note JSON data returns objects. Convert success key's value to BOOL
                        BOOL success = [(NSNumber*)jsonResp[@"success"] boolValue];
                        if (success){
                            
                            //Update the cached token value to be used for other server calls
                            self.token = jsonResp[@"result"][@"token"];
                            [self taskDidRespondWithSuccess:YES msg:nil];
                            
                        } else {
                            [self taskDidRespondWithSuccess:NO
                                                          msg:jsonResp[@"error"]];
                        }
                    } else {
                        [self taskDidRespondWithSuccess:NO
                          msg:[NSString stringWithFormat:@"Error serializing JSON data: %@",[jsonError localizedDescription]]];
                    }
                } else {
                    [self taskDidRespondWithSuccess:NO
                      msg:[NSString stringWithFormat:
                           @"Error in HTTP Repsonse. Status code: %tu",httpResp.statusCode]];
                }
            } else {
                [self taskDidRespondWithSuccess:NO
                  msg:[NSString stringWithFormat:@"Error in dataTaskWithRequest: %@",
                       [error localizedDescription]]];
            }
        }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];

}

-(void)taskDidRespondWithSuccess:(BOOL)success msg:(NSString*)msg;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate NFPServerManagerSessionDidCompleteWithSuccess:success msg:msg];
    });
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


#pragma mark - Upload tasks

-(void)uploadImage:(UIImage*)image;
{
    // Setup query items needed to upload image
    NSMutableArray* queryItems = [NSMutableArray new];
    [queryItems addObject:[NSURLQueryItem
                           queryItemWithName:[NFPServerManager serverKeys][@"token"]
                           value:self.token]];

    // Get URL components
    NSURLComponents* URLcomponents =
    [self NSURLComponentsFromEndpoint:[NFPServerManager serverEndpoints][@"createItem"]
                           queryItems:queryItems];
    
    NSURL* url = URLcomponents.URL;
    
    // Setup NSURLSession. Note that becuase the upload task uses a request, it needs
    // to setup the multi-form encoding for the request that is used for the image data
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSString *boundaryString = @"MULTIPART_FORM_BOUNDARY";
    NSString *contentTypeHeader = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [request addValue:contentTypeHeader forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSString* imageFilename = [NSString stringWithFormat:
        @"NoFilterServerImage_%@", [NSDate date] ];
    
    NSData* imageData = UIImageJPEGRepresentation(image, 1.0f);
    imageData = [imageData multipartFormDataWithBoundaryString:boundaryString
                                             preferredFilename:imageFilename
                                                   contentType:@"image/png"];
    
    // Perform upload task and implement completion handler
    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
        fromData:imageData
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

            if (!error){
                
                NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                         @"Expected response to be of type NSHTTPURLResponse");
                NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
                if (httpResp.statusCode == 200){
                    
//                    NSError* jsonError = nil;
//                    NSDictionary* jsonResp =
//                    [NSJSONSerialization JSONObjectWithData:data
//                                                    options:NSJSONReadingAllowFragments
//                                                      error:&jsonError];
                } else {
                    NSLog(@"Error in http response from Server: %@",httpResp);
                }
            } else {
                NSLog(@"Problem uploading image to server");
            }
            
        }];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
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
    serverKeysDict[@"success"] = @"success";
    serverKeysDict[@"error"] = @"error";
    serverKeysDict[@"request"] = @"request";
    return [NSDictionary dictionaryWithDictionary:serverKeysDict];
}

+(NSDictionary*) serverEndpoints;
{
    
    NSMutableDictionary* serverEndpointsDict = [NSMutableDictionary new];
    serverEndpointsDict[@"getToken"] = @"auth/token";
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
