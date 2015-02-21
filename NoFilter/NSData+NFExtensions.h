//
//  NSData+NFExtensions.h
//  NoFilter
//
//  Created by Tim Ekl on 2015.02.11.
//  Copyright (c) 2015 Tim Ekl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (NFExtensions)

/*!
 Helper for encoding data for use in HTTP multipart form submissions. Call this on data that represents a file (e.g. an image), then use the returned data to upload to a Web server that expects form data.
 
 @param boundaryString The multipart form boundary to use in the encoded form structure. Optional; if you do not provide a string, this method will generate a random UUID for use as a boundary.
 @param preferredFilename The filename to suggest to the server for the encoded data. This name should represent the receiving NSData (e.g. for an image, it should be the name of the image on disk locally). Optional; if you do not provide a filename, this method will use "file".
 @param contentType The MIME content type to provide with the receiver in the returned encoded data. Optional; if you do not provide a filename, this method will use "application/octet-stream".
 @return A new NSData containing the receiver wrapped in a multipart form structure.
 */
- (NSData *)multipartFormDataWithBoundaryString:(NSString *)boundaryString preferredFilename:(NSString *)filename contentType:(NSString *)contentType;

@end
