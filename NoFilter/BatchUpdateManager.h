//
//  TableCollectionViewBatchUpdateManager.h
//  NoFilter
//
//  Created by Ancil on 1/31/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BatchUpdateManager : NSObject

@property (nonatomic,strong) NSMutableArray* insertArray;
@property (nonatomic,strong) NSMutableArray* deleteArray;
@property (nonatomic,strong) NSMutableArray* updateArray;
@property (nonatomic,strong) NSMutableArray* moveArray;

@end
