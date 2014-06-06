//
//  MHSMasterViewController.m
//  OverridingCoreDataSQLiteDatabase
//
//  Created by Maher Suboh on 6/2/14.
//  Copyright (c) 2014 Maher Suboh. All rights reserved.
//

#import "MHSMasterViewController.h"

#import "MHSDetailViewController.h"


typedef void(^myCompletion)(BOOL);



@interface MHSMasterViewController ()
- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath;
@end

@implementation MHSMasterViewController

- (void)awakeFromNib
{
    [super awakeFromNib];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.navigationItem.leftBarButtonItem = self.editButtonItem;

    UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(insertNewObject:)];
    self.navigationItem.rightBarButtonItem = addButton;
    
    
    //////////////////////////////////////////////
    _spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    _spinner.transform = CGAffineTransformMakeScale(1.5, 1.5);
    _spinner.center = self.view.center;
    [_spinner setColor:[UIColor blueColor]];
    [self.view addSubview:_spinner];
    [self.view bringSubviewToFront:_spinner];
    /////////////////////////////////////////////
    
}



- (void)handleOpenURL:(NSURL *)url
{
    [self.spinner startAnimating];

    [self performSelectorOnMainThread:@selector(restoreFromAttachedEmail:) withObject:url waitUntilDone:NO];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.spinner stopAnimating];
    });
    
    
    
}




-(void)restoreFromAttachedEmail:(NSURL *)url
{
    
    [self myBlockMethod:url theCompleteStatus:^(BOOL finished)  {
        // myBlockMethod method just download or load the sqlite file from the server to a NSString String variable and check if it is there and no error, before we Parse it into an array.
        
        
        if(finished)
        {
            //Delete all *.sqlite file  from IOS App Document/Inbox sandbox
            [self removeAllSQLiteInboxFiles];

            
                NSLog(@"Success!");
            }
            else
            {
                NSLog(@"No Success!");
            }
    }];

    
    
}


-(void) myBlockMethod:(NSURL *)url theCompleteStatus:(myCompletion)completionBlockStatus
{
    
    
    if (url)
    {
        //Here I am calling the Copy data from the sqlite Attached Email file into Core Data
        NSError * error;
        
        // retrieve the store URL
        NSURL * storeURL = [[_managedObjectContext persistentStoreCoordinator] URLForPersistentStore:[[[_managedObjectContext persistentStoreCoordinator] persistentStores] lastObject]];
        // lock the current context
        [_managedObjectContext lock];
        [_managedObjectContext reset];//to drop pending changes
        
        
        
        //delete the store from the current managedObjectContext
        if ([[_managedObjectContext persistentStoreCoordinator] removePersistentStore:[[[_managedObjectContext persistentStoreCoordinator] persistentStores] lastObject] error:&error])
        {
            // remove the file containing the data
            [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&error];
            
            NSURL *copyToStoreURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"LotteryNumbers.sqlite"];
            
            [self removeAllSQLiteDocumentsFiles];
            
            [self.managedObjectContext reset];  // Clear all potentially cached objects
            [NSFetchedResultsController deleteCacheWithName:@"Master"];
            
            _fetchedResultsController = nil;
            
            [self.tableView reloadData];
            
            NSFileManager  *manager = [NSFileManager defaultManager];
            // Next we copy the sqlite from the inbox folder to the document folder and override *.sqlite app database
            [manager copyItemAtURL:url toURL:copyToStoreURL error:NULL];
            
        }
        [_managedObjectContext unlock];
        
 
    }
    

    
    
    completionBlockStatus(YES);
}




// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

-(void) removeAllSQLiteDocumentsFiles
{
    
    NSFileManager  *manager = [NSFileManager defaultManager];
    
    NSString *match = @"LotteryNumbers.sqlite-*";
    
    // the preferred way to get the apps documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
//    documentsDirectory = [documentsDirectory stringByAppendingString:@"/Inbox"];
    // grab all the files in the documents dir
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // filter the array for only sqlite files
//    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sqlite'"];
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sqlite' OR SELF like %@", match];
    NSArray *sqliteFiles = [allFiles filteredArrayUsingPredicate:fltr];
    
    // use fast enumeration to iterate the array and delete the files
    for (NSString *sqliteFile in sqliteFiles)
    {
        NSError *error = nil;
        [manager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:sqliteFile] error:&error];
        NSAssert(!error, @"Assertion: SQLite file deletion shall never throw an error.");
    }
 
}


-(void) removeAllSQLiteInboxFiles
{
    
    
    //    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    //    if ([paths count] > 0)
    //    {
    //        NSError *error = nil;
    //        NSFileManager *fileManager = [NSFileManager defaultManager];
    //
    //        // Print out the path to verify we are in the right place
    //        NSString *directory = [paths objectAtIndex:0];
    //        NSLog(@"Directory: %@", directory);
    //
    //        // For each file in the directory, create full path and delete the file
    //        for (NSString *file in [fileManager contentsOfDirectoryAtPath:directory error:&error])
    //        {
    //            NSString *filePath = [directory stringByAppendingPathComponent:file];
    //            NSLog(@"File : %@", filePath);
    //
    //            BOOL fileDeleted = [fileManager removeItemAtPath:filePath error:&error];
    //
    //            if (fileDeleted != YES || error != nil)
    //            {
    //                // Deal with the error...
    //            }
    //        }
    //
    //    }
    
    
    NSFileManager  *manager = [NSFileManager defaultManager];
    
    //    NSString *match = @"LotteryNumbers.sqlite-*";
    
    // the preferred way to get the apps documents directory
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    documentsDirectory = [documentsDirectory stringByAppendingString:@"/Inbox"];
    // grab all the files in the documents dir
    NSArray *allFiles = [manager contentsOfDirectoryAtPath:documentsDirectory error:nil];
    
    // filter the array for only sqlite files
    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"self ENDSWITH '.sqlite'"];
    //    NSPredicate *fltr = [NSPredicate predicateWithFormat:@"SELF like %@", match];
    NSArray *sqliteFiles = [allFiles filteredArrayUsingPredicate:fltr];
    
    // use fast enumeration to iterate the array and delete the files
    for (NSString *sqliteFile in sqliteFiles)
    {
        NSError *error = nil;
        [manager removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:sqliteFile] error:&error];
        NSAssert(!error, @"Assertion: SQLite file deletion shall never throw an error.");
    }
}


- (void)emailsqliteFile
{
    
    
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
	
    
    if (mailClass != nil)
	{
		// We must always check whether the current device is configured for sending emails
		if ([mailClass canSendMail])
		{
			[self displayComposerSheet];
		}
		else
		{
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Failure"
                                                            message:@"Your device is not setup to send Email!\nPlease Activiate Email Through Settings."
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
		}
	}
	else
	{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Email Failure"
                                                        message:@"Your device is not setup to send Email!\nPlease Activiate Email Through Settings."
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
	}
    
    
    
}



// Displays an email composition interface inside the application. Populates all the Mail fields.
-(void)displayComposerSheet
{
    
    
    // Attach The CSV File to the email
    NSString *tempFileName = @"LotteryNumbers.sqlite";
	NSString *tempFile = [ [NSHomeDirectory() stringByAppendingPathComponent:@"Documents"] stringByAppendingPathComponent:tempFileName];
//	NSString *tempFile = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileName];
    
    NSLog(@"%@",tempFile);
    //    NSFileManager  *manager = [NSFileManager defaultManager];
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:tempFile];
    if (!fileExists)
    {
        [[[UIAlertView alloc] initWithTitle:@"Action Status" message:@"You are trying to email an Empty sqlite File!\nLoading/Importing and Creating Local sqlite File to Email." delegate:nil cancelButtonTitle:@"Close" otherButtonTitles: nil] show];
        NSLog(@"Does not Exists");
    }
    
    
    MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
    picker.mailComposeDelegate = self;
    
    [picker setSubject:@"Email Data sqlite File for Backup and Recovery"];
    
    NSString *locationEmailAddress1 =  @"xyz@hotmail.com";
    NSString *locationEmailAddress2 =  @"xyz@yahoo.com";
    
    // Set up recipients
    NSArray *toRecipients = [NSArray arrayWithObject:locationEmailAddress1];
    NSArray *ccRecipients = [NSArray arrayWithObjects:locationEmailAddress2,  nil];
    
    [picker setToRecipients:toRecipients];
    [picker setCcRecipients:ccRecipients];
    

    
    [picker addAttachmentData:[NSData dataWithContentsOfFile:tempFile]
                     mimeType:@"application/x-sqlite3"
                     fileName:@"LotteryNumbers.sqlite"];
    
    
    // Fill out the email body text
    NSString *emailBody = [NSString stringWithFormat:@"Emailing Your Data in sqlite Format for Backup and Recovery reasons.\nWe appreciate your opinion and/or any suggestions. We are looking forward to serving you."];
    [picker setMessageBody:emailBody isHTML:NO];
    
    [self presentViewController:picker animated:YES completion:nil];
}

// Dismisses the email composition interface when users tap Cancel or Send. Proceeds to update the message field with the result of the operation.
- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
	// Notifies users about errors associated with the interface
	NSString *emailMessage = @"Email Result: ";
    switch (result)
	{
		case MFMailComposeResultCancelled:
			emailMessage = [emailMessage stringByAppendingString: @"canceled"];
			break;
		case MFMailComposeResultSaved:
			emailMessage = [emailMessage stringByAppendingString: @"saved"];
			break;
		case MFMailComposeResultSent:
            [self removeAllSQLiteInboxFiles];
			emailMessage = [emailMessage stringByAppendingString: @"sent"];
			break;
		case MFMailComposeResultFailed:
			emailMessage = [emailMessage stringByAppendingString: @"failed"];
			break;
		default:
			emailMessage =[emailMessage stringByAppendingString: @"not sent"];
			break;
	}
    NSLog(@"%@",emailMessage);
    [self dismissViewControllerAnimated:YES completion:nil];
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)insertNewObject:(id)sender
{
    

    
    [ self emailsqliteFile];

//    NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
//    NSEntityDescription *entity = [[self.fetchedResultsController fetchRequest] entity];
//    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:[entity name] inManagedObjectContext:context];
//    
//    // If appropriate, configure the new managed object.
//    // Normally you should use accessor methods, but using KVC here avoids the need to add a custom class to the template.
//    [newManagedObject setValue:[NSDate date] forKey:@"timeStamp"];
//    
//    // Save the context.
//    NSError *error = nil;
//    if (![context save:&error]) {
//         // Replace this implementation with code to handle the error appropriately.
//         // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
//        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
//        abort();
//    }
}

#pragma mark - Table View


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    id <NSFetchedResultsSectionInfo> sectionInfo = [self.fetchedResultsController sections][section];
    return [sectionInfo numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    [self configureCell:cell atIndexPath:indexPath];
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSManagedObjectContext *context = [self.fetchedResultsController managedObjectContext];
        [context deleteObject:[self.fetchedResultsController objectAtIndexPath:indexPath]];
        
        NSError *error = nil;
        if (![context save:&error]) {
             // Replace this implementation with code to handle the error appropriately.
             // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }   
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // The table view should not be re-orderable.
    return NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showDetail"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSManagedObject *object = [[self fetchedResultsController] objectAtIndexPath:indexPath];
        [[segue destinationViewController] setDetailItem:object];
    }
}

#pragma mark - Fetched results controller

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController != nil) {
        return _fetchedResultsController;
    }
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    // Edit the entity name as appropriate.
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    // Set the batch size to a suitable number.
    [fetchRequest setFetchBatchSize:20];
    
    // Edit the sort key as appropriate.
    NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeStamp" ascending:NO];
    NSArray *sortDescriptors = @[sortDescriptor];
    
    [fetchRequest setSortDescriptors:sortDescriptors];
    
    // Edit the section name key path and cache name if appropriate.
    // nil for section name key path means "no sections".
    NSFetchedResultsController *aFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest managedObjectContext:self.managedObjectContext sectionNameKeyPath:nil cacheName:@"Master"];
    aFetchedResultsController.delegate = self;
    self.fetchedResultsController = aFetchedResultsController;
    
	NSError *error = nil;
	if (![self.fetchedResultsController performFetch:&error]) {
	     // Replace this implementation with code to handle the error appropriately.
	     // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. 
	    NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
	    abort();
	}
    
    return _fetchedResultsController;
}    

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo
           atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type
{
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableView = self.tableView;
    
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:@[newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
}


/*
// Implementing the above methods to update the table view in response to individual changes may have performance implications if a large number of changes are made simultaneously. If this proves to be an issue, you can instead just implement controllerDidChangeContent: which notifies the delegate that all section and object changes have been processed. 
 
 - (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    // In the simplest, most efficient, case, reload the table view.
    [self.tableView reloadData];
}
 */

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
//    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
//    cell.textLabel.text = [[object valueForKey:@"timeStamp"] description];
    
    
    NSManagedObject *object = [self.fetchedResultsController objectAtIndexPath:indexPath];
    
    
    cell.textLabel.text = [[object valueForKey:@"a_GameName"] description];
    
    UIImage *currentCellImage;
    currentCellImage = [UIImage imageWithData:(NSData *)[object valueForKey:@"b_LogoImage"] ] ;
    cell.imageView.image  = currentCellImage;
}

@end
