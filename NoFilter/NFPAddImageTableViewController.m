//
//  NFPAddImageTableViewController.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MobileCoreServices/MobileCoreServices.h>

#import "NFPAddImageTableViewController.h"
#import "PhotoTableViewController.h"
#import "AppDelegate.h"

@interface NFPAddImageTableViewController () <UIImagePickerControllerDelegate,
    UINavigationControllerDelegate>

@end

static NSString* const kCellReuseIdentifier = @"addImageTableViewCell";

@implementation NFPAddImageTableViewController

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.imageSources != nil,@"Expected imageSources to be set");
    
    self.navigationItem.title = NSLocalizedString(@"Image Sources", nil);
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView
    numberOfRowsInSection:(NSInteger)section {
    return [self.imageSources count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView
         cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell =
        [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier
                                        forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = self.imageSources[indexPath.row];
    return cell;
}


# pragma mark - TableView Delegate

-(void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIViewController* nextVC;
    
    NSString* imageSource = self.imageSources[indexPath.row];
    
    if ([imageSource isEqualToString:NSLocalizedString(@"Photo Media Library",nil)])
    {
        nextVC = [PhotoTableViewController new];
        [self.navigationController pushViewController:nextVC animated:YES];
    }
    else if ([imageSource isEqualToString:NSLocalizedString(@"Camera", nil)])
    {
        [self takePhoto];
    }
    else {
        NSAssert(NO,NSLocalizedString(@"Unexpected imageSource type",nil));
    }
    
}


#pragma mark - UIImagePickerControllerDelegate

- (void)takePhoto;
{
    if (![UIImagePickerController
          isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagePicker.mediaTypes = @[ (__bridge NSString *)kUTTypeImage ];
    imagePicker.delegate = self;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

//dismiss the view controller if the use cancels the camera picker
//(cancel button is part of GUI)
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
    [picker dismissViewControllerAnimated:YES completion:nil];
}

//if user takes photo, unpack photo data from the NSDictionary parameter
- (void)imagePickerController:(UIImagePickerController *)picker
    didFinishPickingMediaWithInfo:(NSDictionary *)info;
{
    NSString *mediaType = info[UIImagePickerControllerMediaType];
    NSAssert(UTTypeConformsTo((__bridge CFStringRef)mediaType, kUTTypeImage),
             @"Expected an image type");
    
    //grab either the edited (by user within the camera app) or the original photo
    UIImage *image = info[UIImagePickerControllerEditedImage];
    if (image == nil) {
        image = info[UIImagePickerControllerOriginalImage];
    }
    
    //save to the device's photo library and update the UI before dismissing
    if (image != nil) {
        UIImageWriteToSavedPhotosAlbum(image, nil, NULL, NULL);
        [[AppDelegate delegate] setUserImage:image];
    }
    
    //dismiss the controller after the image has been updated
    [picker dismissViewControllerAnimated:YES completion:^{
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
}



@end
