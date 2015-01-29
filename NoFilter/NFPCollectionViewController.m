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

@interface NFPCollectionViewController () <NFPThumbnailGeneratorProtocol>
@property (nonatomic,strong) UIImage* image;
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
    
    self.thumbnailgenerator = [[NFPThumbnailGenerator alloc] initWithDelegate:self];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    
    // Set self as observer of AppDelegate's image property
    [[AppDelegate delegate] addObserver:self
                                forKeyPath:@"image"
                                   options:NSKeyValueObservingOptionNew
                                   context:nil];
    
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
    
    // Get thumbnail image based on indexPath
    UIImage* thumbnail = [self.thumbnailgenerator
                               thumbnailAtIndex:indexPath.item];
    
    // If the thumnail is nil, then the thumbnailGenerator is not yet finished
    // with processing the raw image. Thus start the activity view animation
    if (nil == thumbnail){
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

-(void)didGenerateThumbnailAtIndex:(NSUInteger)index;
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
}

-(void) willGenerateThumbnailAtIndex:(NSUInteger)index;
{
    //NOTE: here need to use the insertItemsAtIndexPaths to make sure that the
    // count of items in the collection view gets updated and matches the
    // data source's data. (Don't use reloadAtIndexPath)
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView insertItemsAtIndexPaths:@[indexPath]];
}

-(void) willRegenerateThumbnailAtIndex:(NSUInteger)index;
{
    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
}

-(void) didClearAllThumbnails;
{
    [self.collectionView reloadData];
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

#pragma  mark - KVO for AppDelegate's image property

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context;
{
    AppDelegate* appDel = (AppDelegate*)object;
    UIImage* image = [appDel getUserImage];
    [self.thumbnailgenerator addImage:image];
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
