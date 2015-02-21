//
//  NSData+NFExtensions.m
//  NoFilter
//
//  Created by Tim Ekl on 2015.02.11.
//  Copyright (c) 2015 Tim Ekl. All rights reserved.
//

#import "NSData+NFExtensions.h"

@implementation NSData (NFExtensions)

- (NSData *)multipartFormDataWithBoundaryString:(NSString *)boundaryString preferredFilename:(NSString *)filename contentType:(NSString *)contentType;
{
    if (boundaryString == nil) {
        boundaryString = [[NSUUID UUID] UUIDString];
    }
    
    if (filename == nil) {
        filename = @"file";
    }
    
    if (contentType == nil) {
        contentType = @"application/octet-stream";
    }
    
    NSMutableData *result = [NSMutableData data];
    
    [result appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundaryString] dataUsingEncoding:NSUTF8StringEncoding]];
    [result appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"file\"; filename=\"%@\"\r\n", filename] dataUsingEncoding:NSUTF8StringEncoding]];
    [result appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", contentType] dataUsingEncoding:NSUTF8StringEncoding]];
    [result appendData:self];
    [result appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n", boundaryString] dataUsingEncoding:NSUTF8StringEncoding]];
    
    return [result copy];
}

@end
