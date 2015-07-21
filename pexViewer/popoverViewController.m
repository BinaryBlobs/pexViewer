//
//  popoverViewController.m
//  pexViewer
//
//  Created by Hugh on 7/14/15.
//  Copyright (c) 2015 Binary Blobs. All rights reserved.
//

#import "popoverViewController.h"


//============================================================================================================================================
//============================================================================================================================================

@implementation PexInfo
@end

//============================================================================================================================================
//============================================================================================================================================

@interface popoverViewController ()

@end

@implementation popoverViewController

//============================================================================================================================================

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Change Background color...
    [_image setWantsLayer: YES];
    [_image.layer setBackgroundColor: [[NSColor grayColor] CGColor]];

    [self.delegate pexViewDidLoad];
}

//============================================================================================================================================

-(void) setPexInfo:(PexInfo *) pex
{
    _pexData = pex;
    
    NSString *dims = @"";
    
    if(pex.pngImage)
    {
        dims = [NSString stringWithFormat: @"%d x %d",
                (int) pex.pngImage.size.width,
                (int) pex.pngImage.size.height];;
    }

    BOOL isGravity = [pex.emitterType isEqualToString:@"0"];  // 0 = Gravity, 1 = Radial
    
    [self.image      setImage:       pex.pngImage];
    [self.caption    setHidden:      pex.pngImage ? YES : NO];
    [self.savePNG    setEnabled:     pex.pngImage ? YES : NO];
    
    [self.dimensions setStringValue: dims];
    [self.filename   setStringValue: pex.filename];
    [self.duration   setStringValue: pex.duration];
    [self.particles  setStringValue: pex.particles];
    [self.type       setStringValue: isGravity ? @"Gravity" : @"Radial"];
}

//============================================================================================================================================

- (IBAction)savePNGfile:(id)sender
{
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    
    NSURL *defaultURL = [NSURL fileURLWithPath:[NSString stringWithFormat: @"%@/Desktop", NSHomeDirectory()]];
    
    [savePanel setAllowedFileTypes:     @[@"png"] ];
    [savePanel setNameFieldStringValue: _pexData.filename];
    [savePanel setDirectoryURL:         defaultURL];
    
    [savePanel beginWithCompletionHandler: ^(NSInteger result)
     {
         if(result == NSFileHandlingPanelOKButton)
         {
             NSBitmapImageRep     *bits = [[_pexData.pngImage representations] objectAtIndex: 0];
             NSData           *saveData = [bits representationUsingType: NSPNGFileType properties:nil] ;
             
             [saveData writeToFile: [[savePanel URL] path] atomically: NO];
         }
     }];
}

//============================================================================================================================================

@end
