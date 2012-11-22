//
//  CollectionViewItem.m
//  Unbound
//
//  Created by Bob on 11/6/12.
//  Copyright (c) 2012 Pixite Apps LLC. All rights reserved.
//

#import "CollectionViewItem.h"
#import "Album.h"
#import "BorderedImageView.h"

@interface CollectionViewItem ()
{
    bool isSelected;
}

@end

@implementation CollectionViewItem

-(IBAction)deleteItem:(id)sender
{
    DLog(@"Delete Item");
}


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
        
    }
    
    return self;
}

-(void)awakeFromNib
{
   [self.view setWantsLayer:YES];
    
    [self.albumImageView setWantsLayer:YES];
    [self.stackPhoto1 setWantsLayer:YES];
    [self.stackPhoto2 setWantsLayer:YES];
    [self.stackPhoto3 setWantsLayer:YES];
    
    [self.albumImageView.layer setZPosition:3];
    [self.stackPhoto1.layer setZPosition:2];
    [self.stackPhoto2.layer setZPosition:1];
    [self.stackPhoto3.layer setZPosition:0];
    
    
    
    self.stackPhoto1.objectValue = [NSImage imageNamed:@"temp"];
    self.stackPhoto2.objectValue = [NSImage imageNamed:@"temp-portrait"];
    self.stackPhoto3.objectValue = [NSImage imageNamed:@"temp"];
    
    CATransform3D transform = CATransform3DMakeRotation (0.523598776, 0, 0, 1);
    [self.stackPhoto1.layer setTransform:transform];
    
}

-(void)setRepresentedObject:(id)representedObject
{
    [super setRepresentedObject:representedObject];
    
    
    
}

-(void)setSelected:(BOOL)selected
{
    [super setSelected:selected];
    
    [self.albumImageView setSelected:selected];
}


- (void)doubleClick:(id)sender {
	NSLog(@"double click in the collectionItem");
	if([self collectionView] && [[self collectionView] delegate] && [[[self collectionView] delegate] respondsToSelector:@selector(doubleClick:)]) {
		[[[self collectionView] delegate] performSelector:@selector(doubleClick:) withObject:self];
	}
}

-(void)rightMouseDown:(NSEvent *)theEvent {
    NSLog(@"rightMouseDown:%@", theEvent);
    NSMenu *theMenu = [[NSMenu alloc] initWithTitle:@"Options"];
    [theMenu insertItemWithTitle:@"Delete" action:@selector(deleteItem:) keyEquivalent:@""atIndex:0];
    [NSMenu popUpContextMenu:theMenu withEvent:theEvent forView:self.view];
    //NSMenu *menu = [[NSMenu alloc] initWithTitle:]
    /*NSMenu *menu = [self.delegate menuForCollectionItemView:self];
    [menu popUpMenuPositioningItem:[[menu itemArray] objectAtIndex:0]
                        atLocation:NSZeroPoint
                            inView:self];*/
}



- (id)animationForKey:(NSString *)key
{
    return nil;
}


@end
