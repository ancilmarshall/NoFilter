//
//  NFPCollectionViewController.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//
#import <Photos/Photos.h>

#import "AppDelegate.h"
#import "NFPAddImageTableViewController.h"
#import "NFPCollectionViewController.h"
#import "NFPThumbnailGenerator.h"
#import "BatchUpdateManager.h"

@interface NFPCollectionViewController () <NFPThumbnailGeneratorProtocol>
@property (nonatomic,strong) NFPThumbnailGenerator* thumbnailgenerator;
@end

@implementation NFPCollectionViewController

static NSString * const reuseIdentifier = @"NFPCollectionViewCell";
static NSString * const kAddImageSegueIdentifier = @"addImageSegue";
static NSString * const kDebugSegueIdentifier = @"debugSegue";

#pragma mark - Initialization

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"No Filter", nil);
    
    self.thumbnailgenerator = [NFPThumbnailGenerator sharedInstance];
    self.thumbnailgenerator.delegate = self;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
}


//TODO: not sure if this is needed
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - UICollectionViewDataSource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return [self.thumbnailgenerator count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    
    UICollectionViewCell *cell =
        [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                                  forIndexPath:indexPath];
    
    //remove any content previously added to this cell
    for (UIView* view in [cell.contentView subviews]){
        if ([view isKindOfClass:[UIActivityIndicatorView class]]){
            [((UIActivityIndicatorView*)view) stopAnimating];
        }
        [view removeFromSuperview];
    }
    
    UIActivityIndicatorView *activityIndicatorView =
        [[UIActivityIndicatorView alloc]
         initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    UIImage* thumbnail = [self.thumbnailgenerator thumbnailAtIndex:indexPath.item];
    
    if (!thumbnail){
        [cell.contentView addSubview:activityIndicatorView];
        
        // Perform auto-layout constraints. Center activityIndicatorView in cell
        [NSLayoutConstraint constraintWithItem:cell.contentView
                                     attribute:NSLayoutAttributeCenterX
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:activityIndicatorView
                                     attribute:NSLayoutAttributeCenterX
                                    multiplier:1.0
                                      constant:0.0].active = YES;
        
        [NSLayoutConstraint constraintWithItem:cell.contentView
                                     attribute:NSLayoutAttributeCenterY
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:activityIndicatorView
                                     attribute:NSLayoutAttributeCenterY
                                    multiplier:1.0
                                      constant:0.0].active = YES;
        
        [activityIndicatorView startAnimating];
    }
    else { // thumbnail is available
        UIImageView* thumbnailView = [[UIImageView alloc]
                                      initWithFrame:CGRectMake(0, 0, 100,100)];
        thumbnailView.contentMode = UIViewContentModeScaleAspectFit;
        thumbnailView.clipsToBounds = YES;
//        UIImage* thumbnail = [self.thumbnailgenerator
//                              thumbnailAtIndex:indexPath.item];
        thumbnailView.image = thumbnail;
        cell.contentView.clipsToBounds = YES;
        [cell.contentView addSubview:thumbnailView];
    }
        
    return cell;
}

#pragma mark - UICollectionViewDelegate
//cellSize is a helper function
-(CGSize)cellSize
{
    return (CGSize){.width = 100, .height=100};
}

-(CGSize)collectionView:(UICollectionView *)collectionView
                 layout:(UICollectionViewLayout *)collectionViewLayout
 sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return  [self cellSize];
}

//TODO: not sure why these two functions are not working?
-(CGFloat)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumInteritemSpacingForSectionAtIndex:(NSInteger)section
{
    return 0.0f;
}

-(CGFloat)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
minimumLineSpacingForSectionAtIndex:(NSInteger)section
{
    return  0.0f;
}

#pragma mark - NFPThumbnailGeneratorProtocol

-(void) performBatchUpdatesForManager:(BatchUpdateManager*)manager;
{
    [self.collectionView performBatchUpdates:^{
        for (NSIndexPath* path in manager.insertArray){
            [self.collectionView insertItemsAtIndexPaths:@[path]];
        }
        for (NSIndexPath* path in manager.deleteArray){
            [self.collectionView deleteItemsAtIndexPaths:@[path]];
        }
        for (NSIndexPath* path in manager.updateArray){
            [self.collectionView reloadItemsAtIndexPaths:@[path]];
        }
    } completion:nil];
    
}


#pragma mark - Add Bar Button Item

// Most of the work is done in prepareForSegue:sender:
- (IBAction)addImageToCollectionView:(UIBarButtonItem *)sender
{
    NSParameterAssert(sender = self.navigationItem.rightBarButtonItem);

}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    
    if ([segue.identifier isEqualToString:kAddImageSegueIdentifier]){
        
        // The next view controller is an embedded in a NavigationController,
        // therefore retrieve it by diving down one level to the first child
        // of the NavigationController
        id destVC = [[[segue destinationViewController] childViewControllers]
                     firstObject] ;
        
        
        if ( [destVC isKindOfClass:[NFPAddImageTableViewController class]]){
            
            NFPAddImageTableViewController* vc = (NFPAddImageTableViewController*)destVC;
            NSMutableArray* sources = [NSMutableArray new];
            
            // Add photo library since always available (device and simulator)
            [sources addObject:
             [NSString stringWithString:NSLocalizedString(@"Photo Media Library",nil)]];
            
            // check if Camera is available on device, then add to sources
            if ([UIImagePickerController
                    isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
            {
                [sources addObject:
                 [NSString stringWithString:NSLocalizedString(@"Camera",nil)]];
            }
            
            // Set the destination view controllers imageSources property
            vc.imageSources = [NSArray arrayWithArray:sources];
            
        }
    }
    
    else if ([segue.identifier isEqualToString:kDebugSegueIdentifier])
    {
        NSParameterAssert([sender isKindOfClass:[UILongPressGestureRecognizer class]]);
    }
}

//unwind segue
-(IBAction) cancelAddImageToCollectionView:(UIStoryboardSegue*)segue;
{
    if ([[segue sourceViewController]
            isKindOfClass:[NFPAddImageTableViewController class]])
    {
        [self.navigationController dismissViewControllerAnimated:YES
                                                      completion:nil];
    }
}

//unwind segue
-(IBAction)debugMe:(UIStoryboardSegue*)segue;
{
    [self.thumbnailgenerator performRegenerationOfAllThumbnails];
}

-(IBAction)clearAllThumbnails:(UIStoryboardSegue*)segue;
{
    [self.thumbnailgenerator clearAllThumbnails];
}


#pragma mark - Long Press Gesture Recognizer
-(IBAction) showDebugViewController:(UILongPressGestureRecognizer*)gesture;
{
    NSParameterAssert(gesture.view == self.collectionView);
    
    if ( gesture.state == UIGestureRecognizerStateBegan )
    {
        [self performSegueWithIdentifier:kDebugSegueIdentifier sender:gesture];
    }

}


@end
