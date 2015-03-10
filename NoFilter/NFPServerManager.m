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

//TODO: Make this an enum of 3 states
#define BACKGROUND_DOWNLOAD 1
#define FOREGROUND_DOWNLOAD_JSON 0

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
@property (nonatomic,strong) NSURLSession* backgroundDownloadSession;
@property (nonatomic,strong) NSOperationQueue* backgroundDownloadQueue;

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

-(NSURL*)URLForServerEndpoint:(NSString*)endpoint query:(NSArray*)queryNames optionalQueryData:(NSDictionary*)optionalData
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
    
    //insert additional query name/value pair from the optionalData dictionary
    if (optionalData!=nil){
        for (NSString* key in [optionalData allKeys]){
        [queryItems addObject:
            [NSURLQueryItem queryItemWithName:key value:optionalData[key]]];
        }
    }
    
    NSURLComponents* URLcomponents = [self NSURLComponentsFromEndpoint:endpoint
                                                            queryItems:queryItems];

    return URLcomponents.URL;
    
}

-(NSURL*)URLForServerEndpoint:(NSString*)endpoint query:(NSArray*)queryNames;
{
    return [self URLForServerEndpoint:endpoint query:queryNames optionalQueryData:nil];
}

-(NSURL*)URLForServerEndpoint:(NSString*)endpoint;
{
    return [self URLForServerEndpoint:endpoint query:@[] optionalQueryData:nil];
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
    NSURL* url = [self URLForServerEndpoint:@"auth/token"
        query:@[@"app_key",@"app_secret",@"username",@"password"]];
    
    // Configure the NSURLSession
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
                                            completionHandler:
        ^(NSData *data, NSURLResponse *response, NSError *error) {
            
            JSONPaserBlockType jsonParserBlock = ^(NSDictionary* jsonResp){
                self.token = jsonResp[@"result"][@"token"];
                //Update the cached list of items on server during logon
                [self getItemList];
                [self didLoginSuccessfully];
            };
            
            [self parseData:data response:response error:error handler:jsonParserBlock];
    }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
}

/*
 * getItemList - retrieves the list of images on the NoFilter server
 *  Response is JSON with the following keys:
 *   "result" - array of item dictionaries, with item_id stored in key "id"
 */
-(void) getItemList;
{
    
    // Setup query items needed to get list from server
    NSURL* url = [self URLForServerEndpoint:@"item/list" query:@[@"username"]];
    
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
                    id itemID = item[@"id"];
                    [ids addObject:itemID];
                }
                self.imageIDs = ids;
                [self syncImages];
            };

            [self parseData:data response:response error:error handler:jsonParser];
        }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
    
}


-(void)uploadImage:(NFPImageData*)imageData context:(NSManagedObjectContext*)context;
{
    // Setup query items needed to upload image
    NSURL* url = [self URLForServerEndpoint:@"item/create"];

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
    
    //Use dateformatter
    static NSDateFormatter* dateformatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateformatter = [[NSDateFormatter alloc] init];
    });
    
    dateformatter.timeStyle = NSDateIntervalFormatterMediumStyle;
    dateformatter.dateStyle = NSDateIntervalFormatterMediumStyle;
    
    NSString* imageFilename = [NSString stringWithFormat:
        @"NoFilterServerImage_%@", [dateformatter stringFromDate:[NSDate date]]];
    
    NSData* imageDataToUpload = UIImageJPEGRepresentation(imageData.image, 1.0f);
    imageDataToUpload = [imageDataToUpload multipartFormDataWithBoundaryString:boundaryString
                                             preferredFilename:imageFilename
                                                   contentType:@"image/png"];
    
    
    // Perform upload task and implement completion handler
    NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request
        fromData:imageDataToUpload
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            JSONPaserBlockType jsonParserBlock = ^(NSDictionary* jsonResp){
                NSLog(@"Image uploaded");
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




-(void) downloadItemWithID:(NSUInteger)itemID;
{
    
    NSLog(@"Beginning download with id: %tu",itemID);
    NSString* serverEndpoint = @"item/get_raw";
    if (FOREGROUND_DOWNLOAD_JSON && !BACKGROUND_DOWNLOAD){
        serverEndpoint = @"item/get";
    }
    NSURL* url = [self URLForServerEndpoint:serverEndpoint query:@[] optionalQueryData:@{@"item_id":[NSString stringWithFormat:@"%tu",itemID]}];

    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    if(BACKGROUND_DOWNLOAD){
        //get the raw image from the NoFilter server using API endpoing item/get_raw

        [self createBackgroundDownloadSessionIfNeeded];
        
        NSURLSessionDownloadTask* task = [self.backgroundDownloadSession
                                          downloadTaskWithRequest:request];
        //TODO: use a string, one that can be regenerated after app re-launches in background
        [self.taskIDImageIDDict setValue:@(itemID)
            forKey:[NSString stringWithFormat:@"%tu",task.taskIdentifier]];

        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [task resume];
        
    } else {
        
        NSURLSessionConfiguration* config = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        NSURLSession* session = [NSURLSession sessionWithConfiguration:config];
            
        NSURLSessionDataTask* task = [session dataTaskWithRequest:request
            completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                
            if(FOREGROUND_DOWNLOAD_JSON){
                //Use NoFilter API endpoint item/get to get base64encoded data
                JSONPaserBlockType jsonParser = ^(NSDictionary* jsonResp){
                    NSDictionary* result = jsonResp[@"result"];
                    NSString* dataString = result[@"data"];
                    NSData* returnedData=[[ NSData alloc] initWithBase64EncodedString:dataString options:NSDataBase64DecodingIgnoreUnknownCharacters];
                    UIImage* image = [UIImage imageWithData:returnedData];
                    //Update the cached token value to be used for other server calls
                    [[NFPThumbnailGenerator sharedInstance] addDownloadedImage:image withID:itemID];
                };
                    
                [self parseData:data response:response error:error handler:jsonParser];
                    
            } else {
                //Use NoFilter API endpoint item/get_raw to get raw binary data
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                UIImage* image = [UIImage imageWithData:data];
                [[NFPThumbnailGenerator sharedInstance] addDownloadedImage:image withID:itemID];
            }
        }];
        
        [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
        [task resume];

    }
}

-(void)createBackgroundDownloadSessionIfNeeded;
{
    NSURLSessionConfiguration* config = [NSURLSessionConfiguration
                                         backgroundSessionConfigurationWithIdentifier:kBackgroundSessionIdentifier];
    
    self.backgroundDownloadQueue = [[NSOperationQueue alloc] init];
    self.backgroundDownloadQueue.name = kBackgroundSessionIdentifier;
    
    //only create a new background download session if one is not already in use
    if (self.backgroundDownloadSession == nil){
        self.backgroundDownloadSession =
        [NSURLSession sessionWithConfiguration:config
                                      delegate:self
                                 delegateQueue:self.backgroundDownloadQueue];
    }
}

-(void)deleteImageWithID:(NSUInteger)itemID;
{
    NSLog(@"Beginning deletion of item with id: %tu",itemID);
    
    NSURL* url = [self URLForServerEndpoint:@"item/delete" query:@[]
                          optionalQueryData:@{@"item_id":[NSString stringWithFormat:@"%tu",itemID]}];
    
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSURLSessionConfiguration* ephemconfig = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    NSURLSession* session = [NSURLSession sessionWithConfiguration:ephemconfig];
    
    
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request
        completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

            JSONPaserBlockType jsonParser = ^(NSDictionary* jsonResp){
                //do nothing here with the returned response data
                //TODO: Do I need to do something?
                };
            [self parseData:data response:response error:error handler:jsonParser];
        
        }];
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    [task resume];
}

-(void)deleteAllImagesOnServer;
{
    for (id item in self.imageIDs){
        NSUInteger imageID = [(NSNumber*)item unsignedIntegerValue];
        [self deleteImageWithID:imageID];
    }
    
}


-(void)syncImages;
{
    //Ordered Set of NSNumbers (of NSUInteger)
    NSMutableOrderedSet* clientImageIDSet =
        [NSMutableOrderedSet orderedSetWithArray:[[NFPThumbnailGenerator sharedInstance] allImageIDs]];
    
    //Ordered Set of NSNumbers (of NSUInteger)
    NSOrderedSet* serverImageIDSet =
        [NSMutableOrderedSet orderedSetWithArray:self.imageIDs];
    
    NSMutableOrderedSet* intersectionSet =
        [NSMutableOrderedSet orderedSetWithOrderedSet:clientImageIDSet];
    [intersectionSet intersectOrderedSet:serverImageIDSet];
    
    NSMutableOrderedSet* toUploadSet =
        [NSMutableOrderedSet orderedSetWithOrderedSet:clientImageIDSet];
    [toUploadSet minusOrderedSet:intersectionSet];
    
    NSMutableOrderedSet* toDownloadSet =
        [NSMutableOrderedSet orderedSetWithOrderedSet:serverImageIDSet];
    [toDownloadSet minusOrderedSet:intersectionSet];
    
    for (NSNumber* toDownloadImageId in toDownloadSet)
    {
        NSUInteger imageID = [toDownloadImageId unsignedIntegerValue];
        [self downloadItemWithID:imageID];
    }
    
}

#pragma mark - delegate methods interface

-(void)taskFailedWithErrorMessage:(NSString*)errorMsg;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate NFPServerManagerTaskFailedWithErrorMessage:errorMsg];
    });
}

-(void)didLoginSuccessfully;
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.delegate NFPServerManagerDidLoginSuccessfully];
    });
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
            [self taskFailedWithErrorMessage:[NSString stringWithFormat:
                @"Error in HTTP Repsonse. Status code: %tu",httpResp.statusCode]];
        }
    } else {
        NSLog(@"Server responded with error: %@",[error localizedDescription]);
        [self taskFailedWithErrorMessage:[NSString stringWithFormat:
            @"Error in NSURLSessionTask: %@",[error localizedDescription]]];
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
            
            jsonParserBlock(jsonResp);
            
        } else {
            [self taskFailedWithErrorMessage:jsonResp[@"error"]];
        }
    } else {
        [self taskFailedWithErrorMessage:[NSString stringWithFormat:
            @"Error serializing JSON data: %@",[jsonError localizedDescription]]];
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
    //NSURL* downloadURL = [self appDocumentsURLForItemID:imageID];
    
    //TODO: error handling
    //[[NSFileManager defaultManager] moveItemAtURL:location toURL:downloadURL error:NULL];
    //dispatch_async(dispatch_get_main_queue(), ^{
    
    //if ( [self.backgroundDownloadQueue operationCount] == 0 ){
        //[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
        //self.backgroundDownloadSession = nil;
        //self.backgroundDownloadQueue = nil;
    //}

    //});
    NSLog(@"Download Complete for id: %tu",imageID);
    
    //UIImage* image = [[UIImage alloc] initWithContentsOfFile: [downloadURL path]];
    UIImage* image = [[UIImage alloc] initWithContentsOfFile: [location path]];
    [[NFPThumbnailGenerator sharedInstance] addDownloadedImage:image withID:imageID];
}

- (NSURL *)appDocumentsURLForItemID:(NSUInteger)itemID;
{
    NSError* directoryError;
    NSURL* directory = [[NSFileManager defaultManager]
                            URLForDirectory:NSDocumentDirectory
                                   inDomain:NSUserDomainMask
                          appropriateForURL:nil
                                     create:NO
                                      error:&directoryError];
    
    if (directoryError){
        NSAssert(NO,@"Error opening a directory in the User's Documents directory");
    }
    
    NSURL* fileURL = [[directory URLByAppendingPathComponent:
                       [NSString stringWithFormat:@"image_with_id_%tu",itemID]]
                      
                      URLByAppendingPathExtension:@"jpg"];
    return fileURL;
}

#pragma mark - NSURLSessionDelegate

/*
 * This is a regular event that happens when the background nsurl session is complete
 * Here we need to call the completion handler that was passed to use by the system
 * so that the system knows we are finished handling the background events. The system
 * can then complete it's own tasks, and wrap up the background session stuff.
 * Note that this is when all the events for this session is complete, ie. it could
 * be several download tasks which are handled by the download delegate.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session;
{
    NSParameterAssert(session == self.backgroundDownloadSession);
    
    NSAssert(self.backgroundDownloadCompletionHandler != nil, @"When finishing background events, expected to have a completion handler");
    self.backgroundDownloadCompletionHandler();
    self.backgroundDownloadCompletionHandler = nil;
}

#pragma mark - debugging methods

-(void)addMutlipleImagestoNFPThumbnailGenerator;
{
    UIImage* image1 = [UIImage imageNamed:@"kitten1.jpg"];
    UIImage* image2 = [UIImage imageNamed:@"kitten2.jpg"];
    UIImage* image3 = [UIImage imageNamed:@"kitten3.jpg"];
    
    [[NFPThumbnailGenerator sharedInstance] addImage:image1];
    [[NFPThumbnailGenerator sharedInstance] addImage:image2];
    [[NFPThumbnailGenerator sharedInstance] addImage:image3];
    
}


@end
