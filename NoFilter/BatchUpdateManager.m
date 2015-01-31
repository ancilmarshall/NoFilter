//
//  TableCollectionViewBatchUpdateManager.m
//  NoFilter
//
//  Created by Ancil on 1/31/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "BatchUpdateManager.h"

@implementation BatchUpdateManager

- (NSMutableArray*) insertArray;
{
    if (!_insertArray){
        _insertArray = [NSMutableArray new];
    }
    return _insertArray;
}

- (NSMutableArray*) deleteArray;
{
    if (!_deleteArray){
        _deleteArray  = [NSMutableArray new];
    }
    return _deleteArray;
}

- (NSMutableArray*) updateArray;
{
    if (!_updateArray){
        _updateArray = [NSMutableArray new];
    }
    return _updateArray;
}

- (NSMutableArray*) moveArray;
{
    if (!_moveArray){
        _moveArray = [NSMutableArray new];
    }
    return _moveArray;
}


@end
