//
//  NFPImageManagedObjectContext.m
//  NoFilter
//
//  Created by Ancil on 1/30/15.
//  Copyright (c) 2015 Ancil Marshall. All rights reserved.
//

#import "NFPImageManagedObjectContext.h"

@implementation NFPImageManagedObjectContext

+ (instancetype)contextForStoreAtURL:(NSURL *)storeURL;
{
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"Model" withExtension:@"momd"];
    NSManagedObjectModel *mom = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    NSPersistentStoreCoordinator *psc = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    
    NSError *error = nil;
    NSString *storeType = (storeURL == nil) ? NSInMemoryStoreType : NSSQLiteStoreType;
    if (![psc addPersistentStoreWithType:storeType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Couldn't add store (type=%@): %@", storeType, error);
        return nil;
    }
    
    NFPImageManagedObjectContext *moc = [[self alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    moc.persistentStoreCoordinator = psc;
    return moc;
}

@end
