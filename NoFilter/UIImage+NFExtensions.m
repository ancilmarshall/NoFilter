//
//  UIImage+NFExtensions.m
//  NoFilter
//
//  Created by Tim Ekl on 1/19/14.
//  Copyright (c) 2014 Tim Ekl. All rights reserved.
//

#import "UIImage+NFExtensions.h"

@implementation UIImage (NFExtensions)

- (UIImage *)scaledImageConstrainedToSize:(CGSize)maximumSize;
{
    return [self scaledImageConstrainedToSize:maximumSize contentScale:[[UIScreen mainScreen] scale]];
}

- (UIImage *)scaledImageConstrainedToSize:(CGSize)maximumSize contentScale:(CGFloat)contentScale;
{
#if 1 && defined(DEBUG)
    // Leave a giant delay in Debug builds to stress the importance of threading this method
    sleep(2);
#endif
    
    CGSize currentSize = [self size];
    CGFloat scaleFactor = MIN(maximumSize.width / currentSize.width, maximumSize.height / currentSize.height) * contentScale;
    
    CGSize desiredSize = CGSizeApplyAffineTransform(currentSize, CGAffineTransformMakeScale(scaleFactor, scaleFactor));
    
    UIGraphicsBeginImageContext(desiredSize);
    [self drawInRect:CGRectIntegral((CGRect){.size = desiredSize, .origin = CGPointZero})];
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return [[UIImage alloc] initWithCGImage:[scaledImage CGImage] scale:contentScale orientation:[scaledImage imageOrientation]];
}

@end
