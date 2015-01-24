//
//  NFPAddImageTableViewController.h
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface NFPAddImageTableViewController : UITableViewController
@property (nonatomic,strong) NSArray* imageSources;
-(instancetype)initWithSources:(NSArray*)imageSources;
@end
