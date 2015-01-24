//
//  PhotoCollectionViewController.h
//  UW_HW6_Ancil
//
//  Created by Ancil on 12/16/14.
//  Copyright (c) 2014 Ancil Marshall. All rights reserved.
//

#import <UIKit/UIKit.h>
@class PHAssetCollection;

@interface PhotoCollectionViewController : UICollectionViewController
@property (nonatomic,strong) PHAssetCollection* album;
@end
