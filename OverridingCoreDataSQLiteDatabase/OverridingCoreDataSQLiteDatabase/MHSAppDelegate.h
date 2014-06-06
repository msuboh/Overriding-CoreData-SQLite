//
//  MHSAppDelegate.h
//  OverridingCoreDataSQLiteDatabase
//
//  Created by Maher Suboh on 6/2/14.
//  Copyright (c) 2014 Maher Suboh. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MHSMasterViewController.h"

@interface MHSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;


@property (strong, nonatomic) MHSMasterViewController *controller;
@property (strong, nonatomic) NSString *sqlName;


@end
