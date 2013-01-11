//
//  PIXAppDelegate.m
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/4/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXLoadingWindowController.h"
#import "PIXPhotoStreamWindowController.h"
#import "PIXAlbumWindowController.h"
#import "PIXBCAlbumWindowController.h"
#import <Quartz/Quartz.h>

extern NSString *SearchDidFinishNotification;
extern NSString *kLoadImageDidFinish;

static NSString *IKTaskAsyncOperation = @"IKTaskAsyncOperation";

@interface PIXAppDelegate()

@property (readonly, strong, atomic) NSOperationQueue *backgroundSaveQueue;

- (IBAction)showLoadingWindow:(id)sender;

@end

@implementation PIXAppDelegate

@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize managedObjectContext = _managedObjectContext;

+(PIXAppDelegate *) sharedAppDelegate;
{
    return (PIXAppDelegate *)[[NSApplication sharedApplication] delegate];
}

+(void)presentError:(NSError *)error
{
#ifdef DEBUG
    DLog(@"%@", error);
    NSLog(@"%@",[NSThread callStackSymbols]);
#endif
    if([[NSThread currentThread] isMainThread]) {
        [[NSApplication sharedApplication] presentError:error];
    } else {
        [[NSApplication sharedApplication] performSelectorOnMainThread:@selector(presentError:) withObject:error waitUntilDone:NO];
    }
}

-(NSOperationQueue *)globalBackgroundSaveQueue;
{
    if (_backgroundSaveQueue == NULL)
    {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _backgroundSaveQueue = [[NSOperationQueue alloc] init];
            [_backgroundSaveQueue setName:@"com.pixite.thumbnail.generator"];
            [_backgroundSaveQueue setMaxConcurrentOperationCount:10];
        });
        
    }
    return _backgroundSaveQueue;
}

-(void)testNotification:(NSNotification *)note
{
    DLog(@"note : %@", note);
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Insert code here to initialize your application
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(testNotification:) name:IKTaskAsyncOperation object:nil];
    
    //Notification for spotlight fetches
    [[NSNotificationCenter defaultCenter] addObserverForName:SearchDidFinishNotification object:self.spotLightFetchController queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:SearchDidFinishNotification object:self.spotLightFetchController];
        DLog(@"Finished loading photos");
        [self photosFinishedLoading:note];
        [self updateAlbumsPhotos];
    }];
    
    //Notification for standard fetches
    [[NSNotificationCenter defaultCenter] addObserverForName:@"PhotoLoadingFinished" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"PhotoLoadingFinished" object:self];
        //[self loadAlbums];
        //
        DLog(@"Finished loading photos");
        [self updateAlbumsPhotos];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:@"AlbumLoadingFinished" object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AlbumLoadingFinished" object:self];
        [self loadPhotos];
    }];
    
}

- (IBAction)showLoadingWindow:(id)sender {
    
    if (loadingWindow == nil) {
        loadingWindow = [[PIXLoadingWindowController alloc] initWithWindowNibName:@"PIXLoadingWindow"];
    }
    [loadingWindow showWindow:self];
}

- (IBAction)showBrowserWindow:(id)sender {
    
    if (browserWindow == nil) {
        browserWindow = [[PIXPhotoStreamWindowController alloc] initWithWindowNibName:@"PIXPhotoStreamWindowController"];
    }
    [browserWindow showWindow:self];
}

- (IBAction)showAlbumsWindow:(id)sender {
    
    if (albumsWindow == nil) {
        albumsWindow = [[PIXAlbumWindowController alloc] initWithWindowNibName:@"PIXAlbumWindowController"];
    }
    [albumsWindow showWindow:self];
}

- (IBAction)showCollectionsWindow:(id)sender {
    
    if (collectionsWindow == nil) {
        collectionsWindow = [[PIXBCAlbumWindowController alloc] initWithWindowNibName:@"PIXBCAlbumWindowController"];
    }
    [collectionsWindow showWindow:self];
}

// Returns the directory the application uses to store the Core Data store file. This code uses a directory named "com.pixite.UnboundCoreDataUtility" in the user's Application Support directory.
- (NSURL *)applicationFilesDirectory
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *appSupportURL = [[fileManager URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    return [appSupportURL URLByAppendingPathComponent:@"com.pixite.UnboundCoreDataUtility"];
}

// Creates if necessary and returns the managed object model for the application.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel) {
        return _managedObjectModel;
    }
	
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"UnboundCoreDataUtility" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.)
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) {
        return _persistentStoreCoordinator;
    }
    
    NSManagedObjectModel *mom = [self managedObjectModel];
    if (!mom) {
        NSLog(@"%@:%@ No model to generate a store from", [self class], NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationFilesDirectory = [self applicationFilesDirectory];
    NSError *error = nil;
    
    NSDictionary *properties = [applicationFilesDirectory resourceValuesForKeys:@[NSURLIsDirectoryKey] error:&error];
    
    if (!properties) {
        BOOL ok = NO;
        if ([error code] == NSFileReadNoSuchFileError) {
            ok = [fileManager createDirectoryAtPath:[applicationFilesDirectory path] withIntermediateDirectories:YES attributes:nil error:&error];
        }
        if (!ok) {
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    } else {
        if (![properties[NSURLIsDirectoryKey] boolValue]) {
            // Customize and localize this error.
            NSString *failureDescription = [NSString stringWithFormat:@"Expected a folder to store application data, found a file (%@).", [applicationFilesDirectory path]];
            
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            [dict setValue:failureDescription forKey:NSLocalizedDescriptionKey];
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:101 userInfo:dict];
            
            [[NSApplication sharedApplication] presentError:error];
            return nil;
        }
    }
    
    /*NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"UnboundCoreDataUtility.storedata"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSXMLStoreType configuration:nil URL:url options:nil error:&error]) {
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }*/
    NSURL *url = [applicationFilesDirectory URLByAppendingPathComponent:@"UUnboundCoreDataUtility.sqlite"];
    NSPersistentStoreCoordinator *coordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:mom];
    if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType/*NSXMLStoreType*/ configuration:nil URL:url options:nil error:&error]) {
        /*
		 Replace this implementation with code to handle the error appropriately.
		 
		 abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development. If it is not possible to recover from the error, display an alert panel that instructs the user to quit the application by pressing the Home button.
		 
		 Typical reasons for an error here include:
		 * The persistent store is not accessible
		 * The schema for the persistent store is incompatible with current managed object model
		 Check the error message to determine what the actual problem was.
		 */
        
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		if (![fileManager removeItemAtPath:url.path error:&error]) {
            NSLog(@"Failed to remove database file: %@", url);
        }
        
        else {
            if (![coordinator addPersistentStoreWithType:NSSQLiteStoreType/*NSXMLStoreType*/ configuration:nil URL:url options:nil error:&error])
            {
                NSLog(@"Failed to create/open database file: %@", url);
                [[NSApplication sharedApplication] presentError:error];
            }
        }
        
    }
    _persistentStoreCoordinator = coordinator;
    
    return _persistentStoreCoordinator;
}

// Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) 
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        NSMutableDictionary *dict = [NSMutableDictionary dictionary];
        [dict setValue:@"Failed to initialize the store" forKey:NSLocalizedDescriptionKey];
        [dict setValue:@"There was an error building up the data file." forKey:NSLocalizedFailureReasonErrorKey];
        NSError *error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
        [[NSApplication sharedApplication] presentError:error];
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] init];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];

    return _managedObjectContext;
}

// Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
- (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window
{
    return [[self managedObjectContext] undoManager];
}

// Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
- (IBAction)saveAction:(id)sender
{
    NSError *error = nil;
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing before saving", [self class], NSStringFromSelector(_cmd));
    }
    
    if (![[self managedObjectContext] save:&error]) {
        [[NSApplication sharedApplication] presentError:error];
    }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:SearchDidFinishNotification object:self.spotLightFetchController];
    // Save changes in the application's managed object context before the application terminates.
    
    if (!_managedObjectContext) {
        return NSTerminateNow;
    }
    
    if (![[self managedObjectContext] commitEditing]) {
        NSLog(@"%@:%@ unable to commit editing to terminate", [self class], NSStringFromSelector(_cmd));
        return NSTerminateCancel;
    }
    
    if (![[self managedObjectContext] hasChanges]) {
        return NSTerminateNow;
    }
    
    NSError *error = nil;
    if (![[self managedObjectContext] save:&error]) {

        // Customize this code block to include application-specific recovery steps.              
        BOOL result = [sender presentError:error];
        if (result) {
            return NSTerminateCancel;
        }

        NSString *question = NSLocalizedString(@"Could not save changes while quitting. Quit anyway?", @"Quit without saves error question message");
        NSString *info = NSLocalizedString(@"Quitting now will lose any changes you have made since the last successful save", @"Quit without saves error question info");
        NSString *quitButton = NSLocalizedString(@"Quit anyway", @"Quit anyway button title");
        NSString *cancelButton = NSLocalizedString(@"Cancel", @"Cancel button title");
        NSAlert *alert = [[NSAlert alloc] init];
        [alert setMessageText:question];
        [alert setInformativeText:info];
        [alert addButtonWithTitle:quitButton];
        [alert addButtonWithTitle:cancelButton];

        NSInteger answer = [alert runModal];
        
        if (answer == NSAlertAlternateReturn) {
            return NSTerminateCancel;
        }
    }

    return NSTerminateNow;
}

@end
