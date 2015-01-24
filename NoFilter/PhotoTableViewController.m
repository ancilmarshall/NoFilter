//
//  PhotoTableViewController.m
//  UW_HW6_Ancil
//
//  Created by Ancil on 12/16/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import "PhotoTableViewController.h"
#import "PhotoCollectionViewController.h"
#import <Photos/Photos.h>

static NSString* const kCellIdentifier = @"Cell";

@interface PhotoTableViewController ()
@property (nonatomic,strong) PHFetchResult* albumsFetchResult;
@end

@implementation PhotoTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"Photos",nil);
    
    //setup tableview
    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:kCellIdentifier];
    
    //check for authorization
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized){
            return;
        }
        
        //fetch photo asset collection from library by assetcollection type
        self.albumsFetchResult =
        [PHAssetCollection
         fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
         subtype:PHAssetCollectionSubtypeAny
         options:nil];
        
         //since it is not guaranteed that this block is running on main queue,
         //explicitly upload the tableview UI on the main queue
         dispatch_async(dispatch_get_main_queue(), ^{
             [self.tableView reloadData];
         });
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.albumsFetchResult count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellIdentifier
                                                            forIndexPath:indexPath];
    
    PHAssetCollection* collection = self.albumsFetchResult[indexPath.row];
    cell.textLabel.text = collection.localizedTitle;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    return cell;
}

#pragma mark - TableView delegate 

- (void) tableView:(UITableView*)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    PHAssetCollection* album = self.albumsFetchResult[indexPath.row];
    PhotoCollectionViewController* collectionViewController =
        [[PhotoCollectionViewController alloc]
         initWithCollectionViewLayout:[UICollectionViewFlowLayout new]]; // remember flowlayout
    collectionViewController.album = album; //needed to be set
    
    //since this UITableViewController is embedded in a NavigationController, can call pushViewController
    [self.navigationController pushViewController:collectionViewController animated:YES];
    
}

@end
