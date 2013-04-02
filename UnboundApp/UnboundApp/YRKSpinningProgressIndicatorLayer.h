//
//  YRKSpinningProgressIndicatorLayer.h
//  SPILDemo
//
//  Copyright 2009 Kelan Champagne. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>


@interface YRKSpinningProgressIndicatorLayer : CALayer {
    BOOL _isRunning;
    __strong NSTimer *_animationTimer;
    NSUInteger _position;

    CGColorRef _foreColor;
    CGFloat _fadeDownOpacity;

    NSUInteger _numFins;
    __strong NSMutableArray *_finLayers;
}

- (void)toggleProgressAnimation;
- (void)startProgressAnimation;
- (void)stopProgressAnimation;

// Properties and Accessors
@property (readonly) BOOL isRunning;
@property (readwrite, copy) NSColor *color;  // "copy" because we don't retain it -- we create a CGColor from it

@end

// Helper Functions
CGColorRef CGColorCreateFromNSColor(NSColor *nscolor);
NSColor *NSColorFromCGColorRef(CGColorRef cgcolor);
