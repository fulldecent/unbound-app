//
//  PIXPhotoGridViewController.m
//  UnboundApp
//
//  Created by Bob on 1/19/13.
//  Copyright (c) 2013 Pixite Apps LLC. All rights reserved.
//

#import "PIXPhotoGridViewController.h"
#import "PIXAppDelegate.h"
#import "PIXAppDelegate+CoreDataUtils.h"
#import "PIXAlbum.h"
#import "PIXPageViewController.h"
#import "PIXNavigationController.h"
#import "PIXDefines.h"
#import "PIXPhotoGridViewItem.h"
#import "PIXPhoto.h"

@interface PIXPhotoGridViewController ()

@property(nonatomic,strong) NSDateFormatter * titleDateFormatter;

@end

@implementation PIXPhotoGridViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
        
        self.titleDateFormatter = [[NSDateFormatter alloc] init];
        [self.titleDateFormatter setDateStyle:NSDateFormatterLongStyle];
        [self.titleDateFormatter setTimeStyle:NSDateFormatterNoStyle];
        self.selectedItemsName = @"photo";
        
    }
    
    return self;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    [self performSelector:@selector(updateAlbum) withObject:nil afterDelay:0.1];

//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadItems:) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
    
    //
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(albumsChanged:)
//                                                 name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM
//                                               object:nil];
    
}

-(void)willShowPIXView
{
    [super willShowPIXView];
    
    [self.gridView reloadSelection];
    
}


-(void)setAlbum:(id)album
{
  
    
    if (album != _album)
    {
        _album = album;
        [[[PIXAppDelegate sharedAppDelegate] window] setTitle:[self.album title]];
        
        [self.selectedItems removeAllObjects];
        [self updateToolbar];
        [self updateAlbum];
        
        [self.gridView scrollPoint:NSZeroPoint];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAlbum) name:kUB_ALBUMS_LOADED_FROM_FILESYSTEM object:nil];
        
    }
}

-(void)updateAlbum
{
    self.items = [self fetchItems];
    [self.gridView reloadData];
    [self.gridViewTitle setStringValue:[NSString stringWithFormat:@"%ld photos from %@", [self.items count], [self.titleDateFormatter stringFromDate:self.album.albumDate]]];
    
}

-(NSMutableArray *)fetchItems
{
    //return [[[PIXAppDelegate sharedAppDelegate] fetchAllPhotos] mutableCopy];
    return [NSMutableArray arrayWithArray:[self.album.photos array]];
}

- (CNGridViewItem *)gridView:(CNGridView *)gridView itemAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    static NSString *reuseIdentifier = @"CNGridViewItem";
    
    PIXPhotoGridViewItem *item = [gridView dequeueReusableItemWithIdentifier:reuseIdentifier];
    if (item == nil) {
        item = [[PIXPhotoGridViewItem alloc] initWithLayout:nil reuseIdentifier:reuseIdentifier];
    }
    
    //    NSDictionary *contentDict = [self.items objectAtIndex:index];
    //    item.itemTitle = [NSString stringWithFormat:@"Item: %lu", index];
    //    item.itemImage = [contentDict objectForKey:kContentImageKey];
    
    PIXPhoto * photo = [self.items objectAtIndex:index];
    [item setPhoto:photo];
    return item;
}

- (BOOL)gridView:(CNGridView *)gridView itemIsSelectedAtIndex:(NSInteger)index inSection:(NSInteger)section
{
    PIXPhoto * photo = nil;
    
    if(index < [self.items count])
    {
        photo = [self.items objectAtIndex:index];
        return [self.selectedItems containsObject:photo];
    }
    
    return NO;
    
}



-(void)showPageControllerForIndex:(NSUInteger)index
{
    PIXPageViewController *pageViewController = [[PIXPageViewController alloc] initWithNibName:@"PIXPageViewController" bundle:nil];
    pageViewController.album = self.album;
    pageViewController.initialSelectedObject = [self.album.photos objectAtIndex:index];
    [self.navigationViewController pushViewController:pageViewController];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CNGridView Delegate

//- (void)gridView:(CNGridView *)gridView didClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
//{
//    CNLog(@"didClickItemAtIndex: %li", index);
//}

- (void)gridView:(CNGridView *)gridView didDoubleClickItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section
{
    CNLog(@"didDoubleClickItemAtIndex: %li", index);
    [self showPageControllerForIndex:index];
}

- (void)gridView:(CNGridView *)gridView rightMouseButtonClickedOnItemAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    PIXPhoto * itemClicked = nil;
    
    if(index < [self.items count])
    {
        itemClicked = [self.items objectAtIndex:index];
    }
    
    // we don't handle clicks off of an album right now
    if(itemClicked == nil) return;
    
    // if this photo isn't in the selection than re-select only this
    if(itemClicked != nil && ![self.selectedItems containsObject:itemClicked])
    {
        [self.selectedItems removeAllObjects];
        [self.selectedItems addObject:itemClicked];
        [self.gridView reloadSelection];
        
        [self updateToolbar];
    }
    
    
    NSMenu *contextMenu = [self menuForObject:itemClicked];
    [NSMenu popUpContextMenu:contextMenu withEvent:event forView:self.view];
    
    // can use this and the self.selectedAlbum array to build a right click menu here
    
    DLog(@"rightMouseButtonClickedOnItemAtIndex: %li", index);
}

#pragma mark - Drag Operations

- (void)gridView:(CNGridView *)gridView dragDidBeginAtIndex:(NSUInteger)index inSection:(NSUInteger)section andEvent:(NSEvent *)event
{
    // move the item we just selected to the front (so it will show up correctly in the drag image)
    PIXPhoto * topPhoto = [self.items objectAtIndex:index];
    
    if(topPhoto)
    {
        [self.selectedItems removeObject:topPhoto];
        [self.selectedItems insertObject:topPhoto atIndex:0];
    }
    
    
    NSPasteboard *dragPBoard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [dragPBoard declareTypes:[NSArray arrayWithObject:NSFilenamesPboardType] owner:nil];
    
    NSMutableArray * filenames = [[NSMutableArray alloc] initWithCapacity:[self.selectedItems count]];
    
    for(PIXPhoto * aPhoto in self.selectedItems)
    {
        [filenames addObject:aPhoto.path];
        //[dragPBoard setString:anAlbum.path forType:NSFilenamesPboardType];
    }
    
    [dragPBoard setPropertyList:filenames
                        forType:NSFilenamesPboardType];
    NSPoint location = [self.gridView convertPoint:[event locationInWindow] fromView:nil];
    location.x -= 90;
    location.y += 90;
    
    
    
    NSImage * dragImage = [PIXPhotoGridViewItem dragImageForPhotos:self.selectedItems size:NSMakeSize(180, 180)];
    [self.gridView dragImage:dragImage at:location offset:NSZeroSize event:event pasteboard:dragPBoard source:self slideBack:YES];
    
}








@end
