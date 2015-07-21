//
//  popoverViewController.h
//  pexViewer
//
//  Created by Hugh on 7/14/15.
//  Copyright (c) 2015 Binary Blobs. All rights reserved.
//

#import <Cocoa/Cocoa.h>

//============================================================================================================================================
//============================================================================================================================================

@interface PexInfo : NSObject

@property (nonatomic, strong) NSPopover  *pexPopover;
@property (nonatomic, strong) NSImage    *pngImage;
@property (nonatomic, strong) NSString   *filename;
@property (nonatomic, strong) NSString   *duration;
@property (nonatomic, strong) NSString   *particles;
@property (nonatomic, strong) NSString   *emitterType;

@end


//============================================================================================================================================
//============================================================================================================================================

@protocol updatePexInfo

//protocol
- (void) pexViewDidLoad;

@end

//============================================================================================================================================
//============================================================================================================================================


@interface popoverViewController : NSViewController

- (void) setPexInfo:(PexInfo *) pex;


@property (strong)  id delegate;
@property (nonatomic, weak) PexInfo    *pexData;

@property (strong) IBOutlet NSImageView *image;
@property (strong) IBOutlet NSTextField *caption;

@property (strong) IBOutlet NSTextField *filename;
@property (strong) IBOutlet NSTextField *duration;
@property (strong) IBOutlet NSTextField *particles;
@property (strong) IBOutlet NSTextField *dimensions;
@property (strong) IBOutlet NSTextField *type;

@property (strong) IBOutlet NSButton    *savePNG;

-(IBAction) savePNGfile:(id)sender;

@end

//============================================================================================================================================
//============================================================================================================================================

