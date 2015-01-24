//
//  NFPAddImageTableViewController.m
//  NoFilter
//
//  Created by Ancil on 1/24/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NFPAddImageTableViewController.h"
#import "PhotoTableViewController.h"
#import "CameraViewController.h"

@interface NFPAddImageTableViewController ()

@end

static NSString* const kCellReuseIdentifier = @"addImageTableViewCell";

@implementation NFPAddImageTableViewController


-(instancetype)initWithSources:(NSArray*)imageSources;
{
    if (self = [super init]){
        _imageSources = imageSources;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    NSAssert(self.imageSources != nil,@"Expected imageSources to be set");
    
    self.navigationItem.title = NSLocalizedString(@"Image Sources", nil);
    
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.imageSources count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:kCellReuseIdentifier forIndexPath:indexPath];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = self.imageSources[indexPath.row];
    return cell;
}


# pragma mark - tableView Delegate
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
        nextVC = [CameraViewController new];
        //[((CameraViewController*)nextVC) takePhoto:nil];
        [self.navigationController pushViewController:nextVC animated:YES];
    }
    else {
        NSAssert(NO,NSLocalizedString(@"Unexpected imageSource type",nil));
    }
    
}


/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
