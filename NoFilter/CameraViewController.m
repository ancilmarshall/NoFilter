//
//  CameraViewController.m
//  UW_HW6_Ancil
//
//  Created by Ancil on 12/16/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import "AppDelegate.h"
#import "CameraViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>

@interface CameraViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@end

@implementation CameraViewController

#pragma mark - initialization and rotation

- (void) viewDidLoad
{
    [super viewDidLoad];
    //self.navigationItem.title = NSLocalizedString(@"Camera",nil);
    [self takePhoto:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)takePhoto:(id)sender;
{
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.mediaTypes = @[ (__bridge NSString *)kUTTypeImage ];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

//dismiss the view controller if the use cancels the camera picker
//(cancel button is part of GUI)
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//if user takes photo, unpack photo data from the NSDictionary parameter
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    NSAssert(UTTypeConformsTo((__bridge CFStringRef)mediaType, kUTTypeImage), @"Expected an image type");
    
    //grab either the edited (by user within the camera app) or the original photo
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (image == nil) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    //save to the device's photo library and update the UI before dismissing
    if (image != nil) {
        UIImageWriteToSavedPhotosAlbum(image, nil, NULL, NULL);
        [((AppDelegate*)[[UIApplication sharedApplication] delegate])
         setUserImage:image];
    }
    
    //dismiss the controller after the image has been updated
    [picker dismissViewControllerAnimated:YES completion:nil];
}

@end
