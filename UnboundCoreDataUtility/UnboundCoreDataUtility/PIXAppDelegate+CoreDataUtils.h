//
//  PIXAppDelegate+CoreDataUtils.h
//  UnboundCoreDataUtility
//
//  Created by Bob on 1/4/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXAppDelegate.h"


@interface PIXAppDelegate (CoreDataUtils)

-(void)photosFinishedLoading:(NSNotification *)note;

-(void)loadPhotos;

-(void)loadAlbums;

-(void)updateAlbumsPhotos;

-(IBAction)testFetchAllPhotos:(id)sender;

-(NSArray *)fetchAllPhotos;

-(IBAction)testFetchAllAlbums:(id)sender;

-(NSArray *)fetchAllAlbums;

-(BOOL)deleteObjectsForEntityName:(NSString *)entityName withUpdateDateBefore:(NSDate *)lastUpdated inContext:(NSManagedObjectContext *)context;

@end
