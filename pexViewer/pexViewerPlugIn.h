//
//  pexViewerPlugIn.h
//  pexViewerPlugIn
//
//  Created by Hugh on 7/14/15.
//  Copyright (c) 2015 Binary Blobs. All rights reserved.
//

#import <AppKit/AppKit.h>

#import "popoverViewController.h"

@class pexViewerPlugIn;

static pexViewerPlugIn *sharedPlugin;

@interface pexViewerPlugIn : NSObject <NSPopoverDelegate, updatePexInfo>

+ (instancetype)sharedPlugin;
- (id)initWithBundle:(NSBundle *)plugin;

//protocol
- (void) pexViewDidLoad;

@end