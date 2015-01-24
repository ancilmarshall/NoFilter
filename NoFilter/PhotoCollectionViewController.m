//
//  PhotoCollectionViewController.m
//  UW_HW6_Ancil
//
//  Created by Ancil on 12/16/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import <Photos/Photos.h>

#import "AppDelegate.h"
#import "PhotoCollectionViewController.h"

@interface PhotoCollectionViewController () <PHPhotoLibraryChangeObserver>
@property (nonatomic,strong) PHFetchResult* assets;
@end

@implementation PhotoCollectionViewController

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = self.album.localizedTitle;
    
    //register self as observer to react to changes in photo library
    [[PHPhotoLibrary sharedPhotoLibrary] registerChangeObserver:self];

    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    // Grab assets
    NSAssert(self.album != nil,@"PHAssetCollection self.album is not set");
    self.assets = [PHAsset fetchAssetsInAssetCollection:self.album options:nil];
    
    // Update UI
    [self.collectionView reloadData];
}

-(void)dealloc
{
    [[PHPhotoLibrary sharedPhotoLibrary] unregisterChangeObserver:self];
}

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self.assets count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];

    //remove any content previously added to this cell (could use a view tag instead?)
    for (UIView* view in [cell.contentView subviews]){
        [view removeFromSuperview];
    }

    //NOTE: important to update the cell's content within the resultHandler block
    PHAsset* asset = [self.assets objectAtIndex:indexPath.item];
    [[PHImageManager defaultManager]
            requestImageForAsset:asset
                      targetSize:[self cellSize]
                     contentMode:PHImageContentModeAspectFill
                        options:nil
                  resultHandler:^(UIImage *result, NSDictionary *info)
                    {
                      //resultHandler may be on a background thread
                      //thus, need to update ui on main thread
                      dispatch_async(dispatch_get_main_queue(), ^{
                          UIImageView* imageView = [[UIImageView alloc] initWithFrame:
                                                    (CGRectMake(0, 0, [self cellSize].width,
                                                                [self cellSize].height))];
                          
                          imageView.contentMode = UIViewContentModeScaleAspectFill;
                          imageView.clipsToBounds = YES; //Not sure why I need to do this for aspect fill ... ( maybe aspect fit? )
                          imageView.image = result;
                          [cell.contentView addSubview:imageView];
                          //try subclassing the UICollectionViewCell to abstract these details
                          //especially of adding subviews and removing them from the cell
                          //or add a custom layer (??)
                      });
                  }];
    return cell;
}

#pragma mark <UICollectionViewDelegate>

//cellSize is a helper function
-(CGSize)cellSize
{
    return (CGSize){.width = 50, .height=50};
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return  [self cellSize];
}

-(CGFloat)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 10.0f;
}

-(CGFloat)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return  10.0f;
}

-(void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath;
{
    
    PHAsset* asset = [self.assets objectAtIndex:indexPath.item];
    
    PHImageRequestOptions* options = [PHImageRequestOptions new];
    options.synchronous = YES; //needed to only call the result handler once, when done
    //otherwise multiple calls can be performed
    
    [[PHImageManager defaultManager]
     requestImageForAsset:asset
     targetSize: self.collectionView.bounds.size
     contentMode:PHImageContentModeAspectFill
     options:options
     resultHandler:^(UIImage *result, NSDictionary *info)
     {
        [((AppDelegate*)[[UIApplication sharedApplication] delegate])
            setUserImage:result];
     }];
    
    AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
    UIViewController* appRootController = [[app.window.rootViewController childViewControllers] firstObject];
    //[self.navigationController popToViewController:appRootController animated:YES];
    [self.navigationController popToRootViewControllerAnimated:YES];
    
}


#pragma mark - PHPhotoLibraryChangeObserver delegate

//NOTE: Taken from the Apple's PHPhotoLibraryChangeObserver class reference documentation
- (void) photoLibraryDidChange:(PHChange *)changeInfo
{
    
    // Photos may call this method on a background queue;
    // switch to the main queue to update the UI.
    dispatch_async(dispatch_get_main_queue(), ^{
        
        // Check for changes to the displayed album itself
        // (its existence and metadata, not its member assets).
        PHObjectChangeDetails *albumChanges = [changeInfo changeDetailsForObject:self.album];
        if (albumChanges) {
            // Fetch the new album and update the UI accordingly.
            self.album = [albumChanges objectAfterChanges];
            self.navigationController.navigationItem.title = self.album.localizedTitle;
        }
        
        // Check for changes to the list of assets (insertions, deletions, moves, or updates).
        PHFetchResultChangeDetails *collectionChanges = [changeInfo changeDetailsForFetchResult:self.assets];
        if (collectionChanges) {
            
            // Get the new fetch result for future change tracking.
            self.assets = collectionChanges.fetchResultAfterChanges;
            
            if (collectionChanges.hasIncrementalChanges)  {
                // Tell the collection view to animate insertions/deletions/moves
                // and to refresh any cells that have changed content.
                [self.collectionView performBatchUpdates:^{
                    NSIndexSet *removed = collectionChanges.removedIndexes;
                    if (removed.count) {
                        [self.collectionView deleteItemsAtIndexPaths:[self indexPathsFromIndexSet:removed]];
                    }
                    NSIndexSet *inserted = collectionChanges.insertedIndexes;
                    if (inserted.count) {
                        [self.collectionView insertItemsAtIndexPaths:[self indexPathsFromIndexSet:inserted]];
                    }
                    NSIndexSet *changed = collectionChanges.changedIndexes;
                    if (changed.count) {
                        [self.collectionView reloadItemsAtIndexPaths:[self indexPathsFromIndexSet:changed]];
                    }
                    if (collectionChanges.hasMoves) {
                        [collectionChanges enumerateMovesWithBlock:^(NSUInteger fromIndex, NSUInteger toIndex) {
                            NSIndexPath *fromIndexPath = [NSIndexPath indexPathForItem:fromIndex inSection:0];
                            NSIndexPath *toIndexPath = [NSIndexPath indexPathForItem:toIndex inSection:0];
                            [self.collectionView moveItemAtIndexPath:fromIndexPath toIndexPath:toIndexPath];
                        }];
                    }
                } completion:nil];
            } else {
                // Detailed change information is not available;
                // repopulate the UI from the current fetch result.
                [self.collectionView reloadData];
            }
        }
    });
}

- (NSArray*) indexPathsFromIndexSet:(NSIndexSet*)indexSet
{
    NSMutableArray* arr = [NSMutableArray new];
    [indexSet enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
         [arr addObject:[NSIndexPath indexPathForItem:index inSection:0]];
    }];
    
    return [arr copy];
}

@end
