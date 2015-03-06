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
#import "NFPImageData.h"
#import "NFPImageData+NFPExtension.h"
#import "AppDelegate.h"
#import "NFPThumbnailGenerator.h"


static NSString* const NFPServerScheme = @"http";
static NSString* const NFPServerPath = @"/api/v1/";
static NSString* const NFPServerHost = @"nofilter.pneumaticsystem.com";

typedef void(^JSONPaserBlockType)(NSDictionary*);
typedef void(^TaskCompletionHandlerType)(NSData*,NSURLResponse*,NSError*);

@interface NFPServerManager() <NSURLSessionDelegate,NSURLSessionDownloadDelegate>

@property (nonatomic,strong) NSDictionary* clientPlistDict;
@property (nonatomic,strong) NSString* token;
@property (nonatomic,strong) NSArray* itemList;
@property (nonatomic,strong) NSArray* imageIDs;
@property (nonatomic,strong) NSMutableDictionary* taskIDImageIDDict;

@end

@implementation NFPServerManager

#pragma mark - Initialization

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

-(NSMutableDictionary*)taskIDImageIDDict;
{
    if (!_taskIDImageIDDict){
        _taskIDImageIDDict = [NSMutableDictionary new];
    }
    return _taskIDImageIDDict;
}

#pragma mark - URL based on Query Items and Server Endpoints

-(NSURL*)URLForQuery:(NSArray*)queryNames severEndpoint:(NSString*)endpoint info:(NSDictionary*)additionalInfo;
{
    //create queryItems
    NSMutableArray* queryItems = [NSMutableArray new];
    for (NSString* queryName in queryNames){
        NSString* queryValue = [self queryValueForName:queryName];
        [queryItems addObject:[NSURLQueryItem queryItemWithName:queryName value:queryValue]];
    }
    
    //always add the token query item, except in the case when requesting the token
    //TODO: distinquish between a general token and a user verified token based on flag
    //TODO: validate token
    if (![queryNames containsObject:@"app_key"] &&
        ![queryNames containsObject:@"app_secret"])
    {
        NSAssert(self.token != nil,@"Cached token value not yet set");
        [queryItems addObject:[NSURLQueryItem
                               queryItemWithName:@"token"
                               value:self.token]];
    }
    
    //insert additional query name/value pair from the additional info dictionary
    if (additionalInfo!=nil){
        for (NSString* key in [additionalInfo allKeys]){
        [queryItems addObject:
            [NSURLQueryItem queryItemWithName:key value:additionalInfo[key]]];
        }
    }
    
    NSURLComponents* URLcomponents = [self NSURLComponentsFromEndpoint:endpoint
                                                            queryItems:queryItems];

    return URLcomponents.URL;
    
}


-(NSURL*)URLForQuery:(NSArray*)queryNames severEndpoint:(NSString*)endpoint;
{
    return [self URLForQuery:queryNames severEndpoint:endpoint info:nil];
}


-(NSString*)queryValueForName:(NSString*)queryName;
{
    
    typedef NSString*(^QueryBlockType)();
    
    NSDictionary* queryValueBlocks = @{
        @"app_key" : ^NSString*{
            return self.clientPlistDict[@"app_key"];
        },
        @"app_secret" : ^NSString*{
            return self.clientPlistDict[@"app_secret"];
        },
        @"username" : ^NSString*{
            return [[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultUsername];
        },
        @"password" : ^NSString*{
            return [[KeyChainManager sharedInstance] passwordForUsername:[[NSUserDefaults standardUserDefaults] valueForKey:kUserDefaultUsername]];
        },
    };
    
    return ((QueryBlockType)queryValueBlocks[queryName])();
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

#pragma mark - NFPServerManager API to perform tasks on remote NoFilter Server
/*
 * Get a token from the server and cache the results
 */
-(void)logonToServer;
{
    
    NSArray* queryItemNames = @[@"app_key",@"app_secret",@"username",@"password"];
    NSURL* url = [self URLForQuery:queryItemNames severEndpoint:@"auth/token"];
    
    NSLog(@"%@",url);
    // Configure the NSURLSession
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    // Call NSRULSession task and implement its completion handler
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            JSONPaserBlockType jsonParserBlock = ^(NSDictionary* jsonResp){
                self.token = jsonResp[@"result"][@"token"];
                //Update the cached list of items on server during logon
                //[self getItemList];
            };
            
            [self parseData:data response:response error:error handler:jsonParserBlock];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
}

//TODO: Change this
-(void)taskDidRespondWithSuccess:(BOOL)success msg:(NSString*)msg;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate NFPServerManagerSessionDidCompleteWithSuccess:success msg:msg];
    });
}


-(void)uploadImage:(NFPImageData*)imageData context:(NSManagedObjectContext*)context;
{
    // Setup query items needed to upload image
    NSURL* url = [self URLForQuery:@[] severEndpoint:@"item/create"];
    
    // Setup NSURLSession. Note that becuase the upload task uses a request, it needs
    // to setup the multi-form encoding for the request that is used for the image data
    // TODO: Should this be a background task? And can I go through the file system? 
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSString *boundaryString = @"MULTIPART_FORM_BOUNDARY";
    NSString *contentTypeHeader = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundaryString];
    [request addValue:contentTypeHeader forHTTPHeaderField:@"Content-Type"];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSString* imageFilename = [NSString stringWithFormat:
        @"NoFilterServerImage_%@", [NSDate date] ];
    
    NSData* imageDataToUpload = UIImageJPEGRepresentation(imageData.image, 1.0f);
    imageDataToUpload = [imageDataToUpload multipartFormDataWithBoundaryString:boundaryString
                                             preferredFilename:imageFilename
                                                   contentType:@"image/png"];
    
    // Perform upload task and implement completion handler
    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
        fromData:imageDataToUpload
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            JSONPaserBlockType jsonParserBlock = ^(NSDictionary* jsonResp){
                NSDictionary* result = jsonResp[@"result"];
                NSUInteger imageID = [result[@"id"] integerValue];
                imageData.imageID = imageID;
                
                [context performBlock:^{
                    NSError* error;
                    if (![context save:&error]){
                        NSLog(@"Unable to update entity: %@",
                              [error localizedDescription]);
                    }
                }];
            };
            
            [self parseData:data response:response error:error handler:jsonParserBlock];
        }];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
}


-(void) getItemList;
{
    
    // Setup query items needed to get list from server
    NSURL* url = [self URLForQuery:@[@"username"] severEndpoint:@"item/list"];
    
    // Setup NSURLSession.
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
 
    // Call NSRULSession task and implement its completion handler
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:
          ^(NSData *data, NSURLResponse *response, NSError *error) {
              
              JSONPaserBlockType jsonParser = ^(NSDictionary* jsonResp){
                  self.itemList = jsonResp[@"result"];
                  NSMutableArray* ids = [NSMutableArray new];
                  for (NSDictionary* item in self.itemList){
                      NSUInteger itemID = [(NSNumber*)item[@"id"] unsignedIntegerValue];
                      [ids addObject:@(itemID)];
                  }
              };
              
              [self parseData:data response:response error:error handler:jsonParser];
              
          }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];

}


-(void) downloadItemWithID:(NSUInteger)itemID;
{
    
    NSLog(@"Beginning download with id: %tu",itemID);
    
    NSURL* url = [self URLForQuery:@[] severEndpoint:@"item/get_raw"
                              info:@{@"item_id":[NSString stringWithFormat:@"%tu",itemID]}];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    // Setup NSURLSession.
    
    if (1){
    
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration
        backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];

    NSOperationQueue* queue = [[NSOperationQueue alloc] init];
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config
                                                          delegate:self
                                                     delegateQueue:queue];
    
    NSURLSessionDownloadTask* task = [session downloadTaskWithRequest:request];
    [self.taskIDImageIDDict setValue:@(itemID)
        forKey:[NSString stringWithFormat:@"%tu",task.taskIdentifier]];

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];

    }
    else {
    
    
    NSURLSessionConfiguration* ephemconfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:ephemconfig];
        
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"Download task complete");
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
                            //NSLog(@"%@",jsonResp);
                            NSDictionary* result = jsonResp[@"result"];
                            NSString* dataString = result[@"data"];
                            NSData* returnedData=[[ NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                            UIImage* image = [UIImage imageWithData:returnedData];
                            //Update the cached token value to be used for other server calls
                            [[NFPThumbnailGenerator sharedInstance] addDownloadedImage:image withID:itemID];
                        }
                    }
                    
                    NSLog(@"Not using JSON, but Raw Data");
                    UIImage* image = [UIImage imageWithData:data];
                    [[NFPThumbnailGenerator sharedInstance] addDownloadedImage:image withID:itemID];
                    
                }
            }
            
        }];
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
    }
}

-(void)deleteAllImagesOnServer;
{
    for (id item in self.imageIDs){
        NSUInteger imageID = [(NSNumber*)item unsignedIntegerValue];
        [self deleteImageWithID:imageID];
    }
    
}

-(void)deleteImageWithID:(NSUInteger)itemID;
{
    NSLog(@"Beginning deletion of item with id: %tu",itemID);
    
    NSURL* url = [self URLForQuery:@[] severEndpoint:@"item/delete"
                              info:@{@"item_id":[NSString stringWithFormat:@"%tu",itemID]}];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSessionConfiguration* ephemconfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:ephemconfig];
    
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
            [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"Deletion task complete");
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

                        BOOL success = [(NSNumber*)jsonResp[@"success"] boolValue];
                        if (!success){
                            NSLog(@"Error Returned from server when deleting item");
                         }
                    }
                }
            }
        }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
}



#pragma mark - Helper Function Blocks to Handle Server Responses and Parse Data

-(void)parseData:(NSData*)data response:(NSURLResponse*)response error:(NSError*)error handler:(JSONPaserBlockType)jsonParser;
{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    if (!error)
    {
        NSAssert([response isKindOfClass:[NSHTTPURLResponse class]],
                 @"Expected response to be of type NSHTTPURLResponse");
        NSHTTPURLResponse* httpResp = (NSHTTPURLResponse*)response;
        
        if (httpResp.statusCode == 200){
            
            [self parseJSONData:data usingBlock:jsonParser];
            
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
}


-(void)parseJSONData:(NSData*)data usingBlock:(JSONPaserBlockType)jsonParserBlock {
    
    
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
            
            //Call the parser block here
            jsonParserBlock(jsonResp);
            
            [self taskDidRespondWithSuccess:YES msg:nil];
            
        } else {
            [self taskDidRespondWithSuccess:NO
                                        msg:jsonResp[@"error"]];
        }
    } else {
        [self taskDidRespondWithSuccess:NO
                                    msg:[NSString stringWithFormat:@"Error serializing JSON data: %@",[jsonError localizedDescription]]];
    }
}




#pragma mark - NSURLSessionDownloadDelegate
/*
 * This function gets called when the download task is complete. Here we must move
 * the data from the temporary url to a permanent location in the app's container
 * This can be called in the background or foreground.
 */

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location;
{
    
    NSNumber* imageIDAsNumber = self.taskIDImageIDDict[[NSString stringWithFormat:@"%tu",downloadTask.taskIdentifier]];
    NSUInteger imageID = [imageIDAsNumber unsignedIntegerValue];
    NSURL* downloadURL = [self appDocumentsURLForItemID:imageID];
    
    //TODO: error handling
    [[NSFileManager defaultManager] moveItemAtURL:location toURL:downloadURL error:NULL];
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

    });
    NSLog(@"Download Complete for id: %tu",imageID);
    
    //NSData* imageData = [NSData dataWithContentsOfURL:downloadURL];
    //UIImage* image = [UIImage imageWithData:imageData];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile: [downloadURL path]];
    NSLog(@"Size of Image is %@", NSStringFromCGSize([image size]));
    [[NFPThumbnailGenerator sharedInstance] addImage:image];
}

- (NSURL *)appDocumentsURLForItemID:(NSUInteger)itemID;
{
    return [[[[NSFileManager defaultManager] URLForDirectory:NSDocumentDirectory
                                                    inDomain:NSUserDomainMask
                                           appropriateForURL:nil
                                                      create:NO
                                                       error:NULL]
             URLByAppendingPathComponent:[NSString stringWithFormat:@"image_with_id_%tu",itemID]]
            URLByAppendingPathExtension:@"jpg"]; //TODO is this a jpg?
}

#pragma mark - NSURLSessionDelegate

/*
 * This is a regular event that happens when the background url session is complete
 * Here we need to call the completion handler that was passed to use by the system
 * so that the system knows we are finished handling the background events. The system
 * can then complete it's own tasks, and wrap up the background session stuff.
 * Note that this is when all the events for this session is complete, ie. it could
 * be several download tasks which are handled by the download delegate.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;
{
//    NSParameterAssert(session == self.backgroundDownloadSession);
//    
//    NSAssert(self.backgroundDownloadCompletionHandler != nil, @"When finishing background events, expected to have a completion handler");
//    self.backgroundDownloadCompletionHandler();
//    self.backgroundDownloadCompletionHandler = nil;
}

#pragma mark - helper functions
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
    serverEndpointsDict[@"getItem"] = @"item/get";
    serverEndpointsDict[@"getRawItem"] = @"item/get_raw";
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
