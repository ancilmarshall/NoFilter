//
//  NFPCollectionViewController.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//
#import <Photos/Photos.h>

#import "NFPAddImageTableViewController.h"
#import "NFPCollectionViewController.h"
#import "NFPThumbnailGenerator.h"

@interface NFPCollectionViewController () <NFPThumbnailGeneratorProtocol>
@property (nonatomic,strong) UIImage* image;
@property (nonatomic,strong) NFPThumbnailGenerator* thumbnailgenerator;
@end

@implementation NFPCollectionViewController

static NSString * const reuseIdentifier = @"NFPCollectionViewCell";
static NSString * const kAddImageSegueIdentifier = @"addImageSegue";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"No Filter", nil);
    
    self.thumbnailgenerator = [[NFPThumbnailGenerator alloc] initWithDelegate:self];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    
    // Set collection view's background color (default is bizzarly black)
    self.collectionView.backgroundColor = [UIColor whiteColor];

    // Setup PhotoLibrary and check for authorization
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
        if (status != PHAuthorizationStatusAuthorized){
            return;
        }
        
        //fetch photo asset collection from library by assetcollection type
        PHFetchResult* albumsFetchResult =
        [PHAssetCollection
         fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
         subtype:PHAssetCollectionSubtypeAny
         options:nil];
        
        
        //grab largest photo asset collection and its latest photo
        NSUInteger largestAssetSize = 0;
        PHFetchResult* largestAlbum;
        
        for (PHAssetCollection* album in albumsFetchResult)
        {
            PHFetchResult* assets = [PHAsset fetchAssetsInAssetCollection:album
                                                                  options:nil];
            NSUInteger assetSize = [assets count];
            if (assetSize > largestAssetSize)
            {
                largestAssetSize = assetSize;
                largestAlbum = assets;
            }
        }
        
        NSUInteger lastAssetIndex = [largestAlbum count] -1;
        NSLog(@"Largest Size %tu",lastAssetIndex+1);
        PHAsset* asset = largestAlbum[lastAssetIndex];
        
        // Grab Image
        __weak NFPCollectionViewController* weak_self = self;
        //NOTE: important to update the cell's content within the resultHandler block
        [[PHImageManager defaultManager]
             requestImageForAsset:asset
             targetSize:CGSizeMake(100, 100)
             contentMode:PHImageContentModeAspectFit
             options:nil
             resultHandler:^(UIImage *result, NSDictionary *info){
                 NSLog(@"Adding image to generator");
                 [weak_self.thumbnailgenerator addImage:result];
             }];
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    //remove any content previously added to this cell (could use a view tag instead?)
    //TODO: not always the same view cell, so need to figure out how to stop animation of activity
    for (UIView* view in [cell.contentView subviews]){
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [((UIActivityIndicatorView*)view) stopAnimating];
        }
        [view removeFromSuperview];
    }
    
    UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    
    // Get thumbnail image based on indexPath
    UIImage* thumbnailImage = [self.thumbnailgenerator thumbnailAtIndex:indexPath.item];
    
    if (nil == thumbnailImage){
        [cell.contentView addSubview:activityIndicatorView];
        [activityIndicatorView startAnimating];
    }
    else {
        UIImageView* thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100,100)];
        thumbnailView.image = thumbnailImage;
        [cell.contentView addSubview:thumbnailView];
    }
        
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

/*
// Uncomment this method to specify if the specified item should be highlighted during tracking
- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}
*/

/*
// Uncomment this method to specify if the specified item should be selected
- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}
*/

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return NO;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	
}
*/


#pragma mark - <NFPThumbnailGeneratorProtocol>
-(void)didFinishGeneratingThumbnailAtIndex:(NSUInteger)index;
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
}


#pragma mark - Add Bar Button Item

- (IBAction)addImageToCollectionView:(UIBarButtonItem *)sender
{
    NSParameterAssert(sender = self.navigationItem.rightBarButtonItem);
    
}


#pragma mark - Navigation

 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
     
     if ([segue.identifier isEqualToString:kAddImageSegueIdentifier]){

         // The next view controller is a embedded in a NavigationController, therefore
         // get it by diving down one level to the first child of the NavigationController
         id destVC = [[[segue destinationViewController] childViewControllers]
                      firstObject] ;
     
         // check if Camera is available.
         
         if ( [destVC isKindOfClass:[NFPAddImageTableViewController class]]){
             
             NFPAddImageTableViewController* vc = (NFPAddImageTableViewController*)destVC;
             NSMutableArray* sources = [NSMutableArray new];
             [sources addObject:
                [NSString stringWithString:NSLocalizedString(@"Photo Media Library",nil)]];
             
             if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
             {
                 [sources addObject:
                  [NSString stringWithString:NSLocalizedString(@"Camera",nil)]];
             }

             vc.imageSources = [NSArray arrayWithArray:sources];
             
         }
         
     }
 }

-(IBAction) cancelAddImageToCollectionView:(UIStoryboardSegue*)segue;
{
    UIViewController* vc = [segue sourceViewController];
    [self.navigationController dismissViewControllerAnimated:vc completion:nil];
}



@end
