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

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"No Filter", nil);
    
    self.thumbnailgenerator = [[NFPThumbnailGenerator alloc] initWithDelegate:self];
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    
    // Set collection view's background color (default is bizzarly black)
    self.collectionView.backgroundColor = [UIColor whiteColor];
    
    // Set as observer of AppDelegate's image property
    AppDelegate* appDel = (AppDelegate*)[UIApplication sharedApplication].delegate;
    [appDel addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:nil];

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
    return [self.thumbnailgenerator count];
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
    activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    
    // Get thumbnail image based on indexPath
    UIImage* thumbnailImage = [self.thumbnailgenerator thumbnailAtIndex:indexPath.item];
    
    if (nil == thumbnailImage){
        [cell.contentView addSubview:activityIndicatorView];
        
        // Perform auto-layout constraints. Center activity view in cell
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
    else {
        UIImageView* thumbnailView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100,100)];
        thumbnailView.image = thumbnailImage;
        [cell.contentView addSubview:thumbnailView];
    }
        
    return cell;
}

#pragma mark - <UICollectionViewDelegate>
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

//TODO: not sure why this is not working?
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

#pragma mark - NFPThumbnailGeneratorProtocol
-(void)didGenerateThumbnailAtIndex:(NSUInteger)index;
{
//    NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView reloadData];
    //TODO: problem here!
    //[self.collectionView reloadItemsAtIndexPaths:[NSArray arrayWithObject:indexPath]];
}

-(void) willGenerateThumbnailAtIndex:(NSUInteger)index;
{
    //TODO: use the indexPath
    //NSIndexPath* indexPath = [NSIndexPath indexPathForItem:index inSection:0];
    [self.collectionView reloadData];
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

//unwind segue
-(IBAction) cancelAddImageToCollectionView:(UIStoryboardSegue*)segue;
{
    if ([[segue sourceViewController]
            isKindOfClass:[NFPAddImageTableViewController class]])
    {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    }
}

#pragma  mark - KVO for AppDelegate's image property
- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
    AppDelegate* appDel = (AppDelegate*)object;
    UIImage* image = [appDel getUserImage];
    [self.thumbnailgenerator addImage:image];
}

@end
