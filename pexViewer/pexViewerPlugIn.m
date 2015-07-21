//
//  pexViewerPlugIn.m
//  pexViewerPlugIn
//
//  Created by Hugh on 7/14/15.
//  Copyright (c) 2015 Binary Blobs. All rights reserved.
//

#import "pexViewerPlugIn.h"

#import "popoverContentView.h"
#import "popoverViewController.h"

#import "TBXML.h"
#import "TBXMLParticleAdditions.h"

#import "NSDataAdditions.h"
#import "NSObject+Blocks.h"

#import "IDEEditorDocument.h"
#import "IDESourceCodeEditor.h"
#import "IDESourceCodeDocument.h"

#import "DVTSourceTextView.h"
//#import "DVTTextStorage.h"


//#define USE_DEBUG_NOTIFICATIONS

//============================================================================================================================================
//============================================================================================================================================

//static NSString * const NSViewFrameDidChangeNotification                  = @"NSViewFrameDidChangeNotification";
static NSString * const IDEEditorDocumentDidChangeNotification            = @"IDEEditorDocumentDidChangeNotification";
static NSString * const IDEEditorContextWillOpenNavigableItemNotification = @"IDEEditorContextWillOpenNavigableItemNotification";
static NSString * const IDEQuickLookDocument                              = @"IDEQuickLookDocument";

@interface Xcode3FileReference <NSObject>
- (id)resolvedFilePath;
@end

//============================================================================================================================================
//============================================================================================================================================


@interface pexViewerPlugIn()

@property (nonatomic, strong, readwrite) NSBundle *bundle;

@property (nonatomic, weak)   IDESourceCodeEditor *editor;
@property (nonatomic, strong) DVTSourceTextView   *editorTextView;

@property (nonatomic, strong) NSMutableArray *notificationObservers;

@property (nonatomic, assign) BOOL  shouldCloseView;

@property (nonatomic, strong) NSPopover  *pexPopover;
@property (nonatomic, strong) PexInfo    *pexData;

@end

//============================================================================================================================================
//============================================================================================================================================



@implementation pexViewerPlugIn

//============================================================================================================================================

+ (instancetype)sharedPlugin
{
    return sharedPlugin;
}

//============================================================================================================================================

- (id)initWithBundle:(NSBundle *)plugin
{
    if (self = [super init])
    {
#ifdef USE_DEBUG_NOTIFICATIONS
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleNotification:) name:nil object:nil];
#endif
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

        // reference to plugin's bundle, for resource access
        self.bundle = plugin;

        self.pexData = [[PexInfo alloc] init];
        
        // Load views
        [self instantiatePopover];

        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        
        [nc addObserver: self
               selector: @selector(didApplicationFinishLaunchingNotification:)
                   name: NSApplicationDidFinishLaunchingNotification
                 object: nil];

        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        self.notificationObservers = [NSMutableArray array];

        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        [self.notificationObservers addObject:[nc addObserverForName: IDEEditorDocumentDidChangeNotification
                                                              object: nil
                                                               queue: nil
                                                          usingBlock: ^(NSNotification *note)
                                               {
                                                   [self onDocumentDidChangeNotification: note];
                                               }]];
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
//        [self.notificationObservers addObject:[nc addObserverForName: NSViewFrameDidChangeNotification
//                                                              object: nil
//                                                               queue: nil
//                                                          usingBlock: ^(NSNotification *note)
//                                               {
//                                                   [self on_XXX_Notification: note];
//                                               }]];
        
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        
        [self.notificationObservers addObject:[nc addObserverForName: IDEEditorContextWillOpenNavigableItemNotification
                                                              object: nil
                                                               queue: nil
                                                          usingBlock: ^(NSNotification *note)
                                               {
                                                   [self onWillOpenNavigableItem: note];
                                               }]];
        
        //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
    }
    return self;
}

//============================================================================================================================================

- (void)instantiatePopover
{
    popoverViewController *vc = [[popoverViewController alloc] initWithNibName: @"popoverContentView" bundle: self.bundle];
    
    vc.delegate = self;

    NSPopover *popover = [[NSPopover alloc] init];
    
    popover.contentViewController = vc;
    popover.behavior              = NSPopoverBehaviorSemitransient;
    popover.delegate              = self;
    popover.animates              = YES;
    
    self.pexPopover = popover;
}

//============================================================================================================================================

#ifdef USE_DEBUG_NOTIFICATIONS
- (void)handleNotification:(NSNotification *)notification
{
//    if([notification.name hasPrefix:@"IDEEditor"])
    //if([notification.name hasPrefix:@"NSView"] )
    {
        NSLog(@"#######  DEBUG >>>  %@, %@", notification.name, [notification.object class]);
    }
    
//    if ([[notification object] isKindOfClass:NSClassFromString(@"IDEQuickLookDocument")])
//    {
//        NSLog(@"#######  DEBUG >>>  IDEQuickLookDocument ****");
//    }
}
#endif

//============================================================================================================================================

- (void)onWillOpenNavigableItem:(NSNotification *)notification
{
    if(self.shouldCloseView)
    {
        [self dismissPopover];
    }
    
    self.shouldCloseView = YES;
}

//============================================================================================================================================

- (void)on_XXX_Notification:(NSNotification *)notification
{
    NSLog(@"#######  WILL CLOSE DEBUG >>>  %@, %@", notification.name, [notification.object class]);

//    NSViewFrameDidChangeNotification, DVTSourceTextView

//    if([[[notification.object class] name]  ] )
//    {
//        NSLog(@"#######  DEBUG >>>  %@, %@", notification.name, [notification.object class]);
//    }
}

//============================================================================================================================================

- (void)onDocumentDidChangeNotification:(NSNotification *)notification
{
    /*
     Be careful with [IDESourceCodeDocument class], use NSClassFromString(@"IDESourceCodeDocument") instead.
     The reason is IDESourceCodeDocument is a private class residing in some dylib loaded after launching Xcode. However,
     since Xcode 6.3.2 plugins are loaded before loading the dylib with IDESourceCodeDocument, and so linker freaks out.
     NSClassFromString(@"IDESourceCodeDocument"), though not perfect, is safer because will return nil until appropriate
     dylib is loaded.
     */
    if (![[notification object] isKindOfClass:NSClassFromString(@"IDESourceCodeDocument")])
    {
        return;
    }
    
    IDESourceCodeDocument *document = [notification object];
     
    for (Xcode3FileReference *fileReference in (NSArray *)[document knownFileReferences])
    {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"
        
        NSString *path = [[fileReference resolvedFilePath] performSelector: @selector(pathString) ];
  
#pragma clang diagnostic pop
        
         NSLog(@"  Filepath: %@", path );
        
        if([path hasSuffix:@".pex"] ||
           [path hasSuffix:@".PEX"] )
        {
            DVTTextStorage *textStorage = [document textStorage];
            
            //NSLog(@"  textStorage: %@",textStorage.contents);
            
            //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
            
            [self parsePexFile: [textStorage.contents string] ];

            [self updatePexView];
            
            //- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
        }
        else
        {
            [self dismissPopover];
        }
    }
    
    NSLog(@"#");
    NSLog(@"#########################################################################################################");
    NSLog(@"#");
    
}

//============================================================================================================================================

- (void)updatePexView
{
    NSResponder *firstResponder = [[NSApp keyWindow] firstResponder];
    
    if( [firstResponder isKindOfClass:NSClassFromString(@"IDENavigatorOutlineView")] )
    {
        self.editorTextView = (DVTSourceTextView *)firstResponder;
        
        [self showPopover];
    }
}

//============================================================================================================================================

- (void)showPopover
{
    popoverViewController *vc = (popoverViewController*) self.pexPopover.contentViewController;
    
    [vc setPexInfo: _pexData];

    [_pexPopover showRelativeToRect: self.editorTextView.bounds
                             ofView: self.editorTextView
                      preferredEdge: /*NSMinYEdge*/NSMaxXEdge];
    
    self.shouldCloseView = NO;
}

//============================================================================================================================================

- (void) dismissPopover
{
    if(_pexPopover)
    {
        [_pexPopover close];
    }
}

//============================================================================================================================================

- (void) pexViewDidLoad
{
    [self updatePexView];
}

//============================================================================================================================================

-(void) parsePexFile: (NSString *) xmlString
{
    NSError *error;
    
    // Create a TBXML instance that we can use to parse the config file
    TBXML *particleXML = [[TBXML alloc] initWithXMLString: xmlString error: &error];
    
    TBXMLElement *rootXMLElement = particleXML.rootXMLElement;
    
    // Make sure we have a root element or we cant process this file
    if (!rootXMLElement)
    {
        NSLog(@"ERROR - ParticleEmitter: Could not find root element in particle config file.");
        assert(0);
    }

    TBXMLElement *textureElement   = TBXML_CHILD (rootXMLElement, @"texture");
    TBXMLElement *durationElement  = TBXML_CHILD (rootXMLElement, @"duration");
    TBXMLElement *particlesElement = TBXML_CHILD (rootXMLElement, @"maxParticles");
    TBXMLElement *typeElement      = TBXML_CHILD (rootXMLElement, @"emitterType");

    _pexData.pngImage  = nil;
    
    if (textureElement)
    {
        _pexData.filename = TBXML_ATTRIB_STRING (textureElement, @"name");
        
        if(_pexData.filename == nil) // legacy
        {
            _pexData.filename = @"-";
        }
        
        if(durationElement)
        {
            _pexData.duration = TBXML_ATTRIB_STRING (durationElement, @"value");
            
            float duration_val = [_pexData.duration floatValue];
            
            _pexData.duration = (duration_val < 0) ? @"INFINITE" : _pexData.duration;
        }
        
        if(particlesElement)
        {
            _pexData.particles = TBXML_ATTRIB_STRING (particlesElement, @"value");;
        }
        
        NSString *fileData = TBXML_ATTRIB_STRING (textureElement, @"data");
        
        if(fileData)
        {
            NSData   *pngData = [[NSData dataWithBase64EncodedString: fileData] gzipInflate] ;
            _pexData.pngImage     = [[NSImage alloc] initWithData: pngData];
        }
        
        if(typeElement)
        {
            _pexData.emitterType = TBXML_ATTRIB_STRING (typeElement, @"value");;
        }
    }
}

//============================================================================================================================================

- (void)didApplicationFinishLaunchingNotification:(NSNotification*)noti
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSApplicationDidFinishLaunchingNotification object:nil];
}

//============================================================================================================================================

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    for(id observer in self.notificationObservers)
    {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
    }
}

//============================================================================================================================================

@end


/*
 2015-07-17 08:39:57.475 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillBecomeActiveNotification, IDEApplication
 2015-07-17 08:39:57.488 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidBecomeMainNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.491 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidBecomeKeyNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.493 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidBecomeActiveNotification, IDEApplication
 2015-07-17 08:39:57.498 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.498 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.498 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.499 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.537 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:57.562 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSPopoverFrame
 2015-07-17 08:39:57.707 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.707 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.708 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.708 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.708 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.708 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.708 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.709 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.709 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.710 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.710 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.710 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.710 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.711 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.711 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.711 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.714 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.714 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.714 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.714 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.715 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.715 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.715 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.715 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.727 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.728 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.728 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.728 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.729 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.729 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.729 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.729 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.730 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.731 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.731 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.731 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.731 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.731 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.732 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.732 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.733 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.733 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.733 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.733 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.745 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.745 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.745 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.745 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.746 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.746 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.746 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.746 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.747 Xcode[1028:14946] #######  DEBUG >>>  DVTSourceExpressionUnderMouseDidChangeNotification, IDEWorkspace
 2015-07-17 08:39:57.747 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.747 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.747 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.748 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.748 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.748 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.748 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.749 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.761 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.761 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.761 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.761 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.921 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.921 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.921 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.921 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.939 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.939 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.940 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.940 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.940 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.941 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.941 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.941 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.941 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.941 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.942 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.942 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.942 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.943 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.943 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.943 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.956 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.956 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.956 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.956 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.957 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.957 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.957 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.957 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.958 Xcode[1028:14946] #######  DEBUG >>>  DVTSourceExpressionUnderMouseDidChangeNotification, IDEWorkspace
 2015-07-17 08:39:57.958 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.958 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.958 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.958 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.959 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.959 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.959 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.959 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.959 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.960 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.960 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.960 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.961 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.961 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.961 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.961 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.972 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.973 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.973 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.973 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:57.989 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:57.990 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:57.990 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:57.990 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.007 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.007 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.007 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.007 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.024 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.025 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.025 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.025 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.042 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.042 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.043 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.043 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.059 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.059 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.059 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.060 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.076 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.076 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.076 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.076 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.093 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.093 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.093 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.093 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.110 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.110 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.110 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.110 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.120 Xcode[1028:14946] #######  DEBUG >>>  IDEWorkspaceDocumentWillWriteStateDataNotification, IDEWorkspaceDocument
 2015-07-17 08:39:58.243 Xcode[1028:14946] #######  DEBUG >>>  DVTSourceExpressionUnderMouseDidChangeNotification, IDEWorkspace
 2015-07-17 08:39:58.515 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.515 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.516 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.516 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.619 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionIsChangingNotification, IDENavigatorOutlineView
 2015-07-17 08:39:58.621 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSVisualEffectView
 2015-07-17 08:39:58.625 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:58.633 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionDidChangeNotification, IDENavigatorOutlineView
 2015-07-17 08:39:58.637 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.637 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.638 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.638 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.638 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.638 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.639 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.639 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.642 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:58.651 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, NSVisualEffectView
 2015-07-17 08:39:58.652 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.652 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.652 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.652 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.653 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:58.653 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:58.653 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:58.653 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:58.814 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorContextWillOpenNavigableItemNotification, IDEEditorContext
 2015-07-17 08:39:58.817 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.817 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:39:58.817 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:39:58.818 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:39:58.818 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:39:58.818 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.821 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceWillGoAwayNotification, NSSurface
 2015-07-17 08:39:58.822 Xcode[1028:14946] #######  DEBUG >>>  NSUndoManagerCheckpointNotification, DVTUndoManager
 2015-07-17 08:39:58.824 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSScroller
 2015-07-17 08:39:58.824 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewWillChangeNotifyingTextViewNotification, (null)
 2015-07-17 08:39:58.824 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewDidChangeTypingAttributesNotification, DVTSourceTextView
 2015-07-17 08:39:58.825 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTControllerContentView
 2015-07-17 08:39:58.826 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceDidComeBackNotification, NSSurface
 2015-07-17 08:39:58.828 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.829 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.829 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSClipView
 2015-07-17 08:39:58.829 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.829 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSScroller
 2015-07-17 08:39:58.829 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextScrollView
 2015-07-17 08:39:58.830 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, IDESourceCodeEditorContainerView
 2015-07-17 08:39:58.830 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceWillGoAwayNotification, NSSurface
 2015-07-17 08:39:58.831 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTMarkedScroller
 2015-07-17 08:39:58.831 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTTextSidebarView
 2015-07-17 08:39:58.832 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.832 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSClipView
 2015-07-17 08:39:58.840 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.841 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.841 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.842 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.850 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.851 Xcode[1028:14946] #######  DEBUG >>>  IDESourceCodeEditorDidFinishSetup, IDESourceCodeEditor
 2015-07-17 08:39:58.852 Xcode[1028:14946] #######  DEBUG >>>  transition from one file to another, __NSDictionaryI
 2015-07-17 08:39:58.853 Xcode[1028:14946] #######  DEBUG >>>  NSViewBoundsDidChangeNotification, NSClipView
 2015-07-17 08:39:58.854 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.854 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewDidChangeSelectionNotification, DVTSourceTextView
 2015-07-17 08:39:58.855 Xcode[1028:14946] #######  DEBUG >>>  IDESourceCodeEditorDidChangeLineSelectionNotification, IDESourceCodeEditor
 2015-07-17 08:39:58.859 Xcode[1028:14946] #######  DEBUG >>>  NSMenuDidRemoveAllItemsNotification, NSMenu
 2015-07-17 08:39:58.860 Xcode[1028:14946] #######  DEBUG >>>  NSMenuDidAddItemNotification, NSMenu
 2015-07-17 08:39:58.862 Xcode[1028:14946] #######  DEBUG >>>  IDENavigableItemCoordinatorObjectGraphChangeNotification, IDENavigableItemCoordinator
 2015-07-17 08:39:58.862 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.863 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.863 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.863 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.864 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSView
 2015-07-17 08:39:58.865 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSTextField
 2015-07-17 08:39:58.865 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSView
 2015-07-17 08:39:58.881 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:58.883 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceDidComeBackNotification, NSSurface
 2015-07-17 08:39:58.902 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, IDEPathControl
 2015-07-17 08:39:58.903 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTControllerContentView
 2015-07-17 08:39:58.904 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, IDESourceCodeEditorContainerView
 2015-07-17 08:39:58.904 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextScrollView
 2015-07-17 08:39:58.904 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, NSClipView
 2015-07-17 08:39:58.904 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:39:58.905 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTTextSidebarView
 2015-07-17 08:39:58.905 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTMarkedScroller
 2015-07-17 08:39:58.906 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentDidChangeNotification, IDESourceCodeDocument
 2015-07-17 08:39:58.916 Xcode[1028:14946]   Filepath: /Users/Hugh/Desktop/pexFrames/pexFrames/Patricles/Starfield_Slow.pex
 2015-07-17 08:39:58.917 Xcode[1028:14946] #######  showPopover()  >>> fileData .... OK
 2015-07-17 08:39:58.917 Xcode[1028:14946] #######  showPopover()  >>> VC       .... OK
 2015-07-17 08:39:58.917 Xcode[1028:14946] #######  showPopover()  >>> vc.image .... OK
 2015-07-17 08:39:58.917 Xcode[1028:14946] #
 2015-07-17 08:39:58.917 Xcode[1028:14946] #########################################################################################################
 2015-07-17 08:39:58.918 Xcode[1028:14946] #
 2015-07-17 08:39:58.922 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSPopoverFrame
 2015-07-17 08:39:58.922 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentShouldCommitEditingNotification, IDESourceCodeDocument
 2015-07-17 08:39:58.925 Xcode[1028:14946] #######  DEBUG >>>  NSUserDefaultsDidChangeNotification, NSUserDefaults
 2015-07-17 08:39:58.958 Xcode[1028:14946] #######  DEBUG >>>  NSUndoManagerCheckpointNotification, DVTUndoManager
 2015-07-17 08:39:58.959 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentWillCloseNotification, IDESourceCodeDocument
 2015-07-17 08:39:58.959 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentWillClose_ForNavigableItemCoordinatorEyesOnly_Notification, IDESourceCodeDocument
 2015-07-17 08:39:58.959 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.960 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.960 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.960 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.960 Xcode[1028:14946] #######  DEBUG >>>  DVTUndoManagerWasResetNotification, DVTUndoManager
 2015-07-17 08:39:58.962 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.962 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.962 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.962 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.964 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.964 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.965 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.965 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:39:58.966 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:58.967 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.968 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:39:58.969 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.977 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:58.977 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:39:58.981 Xcode[1028:14946] #######  DEBUG >>>  NSUserDefaultsDidChangeNotification, NSUserDefaults
 2015-07-17 08:39:59.014 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:59.165 Xcode[1028:14946] #######  DEBUG >>>  DVTSourceExpressionSelectedExpressionDidChangeNotification, IDESourceCodeEditor
 2015-07-17 08:39:59.216 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.216 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.217 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.217 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.232 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.232 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.232 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.233 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.250 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.251 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.251 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.251 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.283 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.283 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.283 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.283 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.319 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.319 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.319 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.319 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.366 Xcode[1028:14946] #######  DEBUG >>>  DVTWeakInterposerRepresentedObjectIsDeallocatingNotification, DVTWeakInterposer_ProxyHelperReference
 2015-07-17 08:39:59.366 Xcode[1028:14946] #######  DEBUG >>>  DVTWeakInterposerRepresentedObjectIsDeallocatingNotification, DVTWeakInterposer_ProxyHelperReference
 2015-07-17 08:39:59.383 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.384 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.384 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.384 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.385 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.385 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.385 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.385 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.399 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.400 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.400 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.400 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.417 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.418 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.418 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.418 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.432 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.433 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.433 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.433 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.449 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.449 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.449 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.450 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.482 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:39:59.482 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:39:59.483 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:39:59.483 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:39:59.611 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:39:59.619 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:39:59.636 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:39:59.967 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:00.713 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:00.713 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:00.713 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:00.714 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:00.915 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionIsChangingNotification, IDENavigatorOutlineView
 2015-07-17 08:40:00.916 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSVisualEffectView
 2015-07-17 08:40:00.920 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:00.933 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionDidChangeNotification, IDENavigatorOutlineView
 2015-07-17 08:40:00.937 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:00.938 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:00.938 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:00.938 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:00.939 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:00.939 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:00.939 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:00.939 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:00.943 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:00.953 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, NSVisualEffectView
 2015-07-17 08:40:00.955 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:00.955 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:00.955 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:00.955 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:00.955 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:00.956 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:00.956 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:00.956 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.113 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorContextWillOpenNavigableItemNotification, IDEEditorContext
 2015-07-17 08:40:01.116 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.116 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:40:01.116 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:40:01.116 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:40:01.117 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, NSConcreteTextStorage
 2015-07-17 08:40:01.117 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.120 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceWillGoAwayNotification, NSSurface
 2015-07-17 08:40:01.120 Xcode[1028:14946] #######  DEBUG >>>  NSUndoManagerCheckpointNotification, DVTUndoManager
 2015-07-17 08:40:01.122 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSScroller
 2015-07-17 08:40:01.123 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewWillChangeNotifyingTextViewNotification, (null)
 2015-07-17 08:40:01.123 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewDidChangeTypingAttributesNotification, DVTSourceTextView
 2015-07-17 08:40:01.123 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTControllerContentView
 2015-07-17 08:40:01.125 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceDidComeBackNotification, NSSurface
 2015-07-17 08:40:01.127 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.127 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.127 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSClipView
 2015-07-17 08:40:01.127 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.128 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSScroller
 2015-07-17 08:40:01.128 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextScrollView
 2015-07-17 08:40:01.128 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, IDESourceCodeEditorContainerView
 2015-07-17 08:40:01.128 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceWillGoAwayNotification, NSSurface
 2015-07-17 08:40:01.129 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTMarkedScroller
 2015-07-17 08:40:01.130 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTTextSidebarView
 2015-07-17 08:40:01.130 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.130 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSClipView
 2015-07-17 08:40:01.138 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.138 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.138 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.139 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.146 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.147 Xcode[1028:14946] #######  DEBUG >>>  IDESourceCodeEditorDidFinishSetup, IDESourceCodeEditor
 2015-07-17 08:40:01.147 Xcode[1028:14946] #######  DEBUG >>>  transition from one file to another, __NSDictionaryI
 2015-07-17 08:40:01.149 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.150 Xcode[1028:14946] #######  DEBUG >>>  NSTextViewDidChangeSelectionNotification, DVTSourceTextView
 2015-07-17 08:40:01.150 Xcode[1028:14946] #######  DEBUG >>>  IDESourceCodeEditorDidChangeLineSelectionNotification, IDESourceCodeEditor
 2015-07-17 08:40:01.152 Xcode[1028:14946] #######  DEBUG >>>  NSViewBoundsDidChangeNotification, NSClipView
 2015-07-17 08:40:01.152 Xcode[1028:14946] #######  DEBUG >>>  IDESourceCodeEditorTextViewBoundsDidChangeNotification, IDESourceCodeEditor
 2015-07-17 08:40:01.154 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSView
 2015-07-17 08:40:01.154 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSTextField
 2015-07-17 08:40:01.154 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSView
 2015-07-17 08:40:01.162 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:01.162 Xcode[1028:14946] #######  DEBUG >>>  NSSurfaceDidComeBackNotification, NSSurface
 2015-07-17 08:40:01.169 Xcode[1028:14946] #######  DEBUG >>>  NSMenuDidRemoveAllItemsNotification, NSMenu
 2015-07-17 08:40:01.169 Xcode[1028:14946] #######  DEBUG >>>  NSMenuDidAddItemNotification, NSMenu
 2015-07-17 08:40:01.171 Xcode[1028:14946] #######  DEBUG >>>  IDENavigableItemCoordinatorObjectGraphChangeNotification, IDENavigableItemCoordinator
 2015-07-17 08:40:01.172 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.172 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.172 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.172 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.190 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:01.207 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, IDEPathControl
 2015-07-17 08:40:01.208 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTControllerContentView
 2015-07-17 08:40:01.209 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, IDESourceCodeEditorContainerView
 2015-07-17 08:40:01.209 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextScrollView
 2015-07-17 08:40:01.209 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, NSClipView
 2015-07-17 08:40:01.209 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:40:01.210 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTTextSidebarView
 2015-07-17 08:40:01.210 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTMarkedScroller
 2015-07-17 08:40:01.211 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentDidChangeNotification, IDESourceCodeDocument
 2015-07-17 08:40:01.211 Xcode[1028:14946]   Filepath: /Users/Hugh/Desktop/pexFrames/pexFrames/Patricles/Stars.pex
 2015-07-17 08:40:01.212 Xcode[1028:14946] #######  showPopover()  >>> fileData .... OK
 2015-07-17 08:40:01.212 Xcode[1028:14946] #######  showPopover()  >>> VC       .... OK
 2015-07-17 08:40:01.213 Xcode[1028:14946] #######  showPopover()  >>> vc.image .... OK
 
 
 2015-07-17 08:40:01.213 Xcode[1028:14946] #
 2015-07-17 08:40:01.213 Xcode[1028:14946] #########################################################################################################
 2015-07-17 08:40:01.213 Xcode[1028:14946] #
 
 
 Clicked from STARS.PEX  to a GROUP folder icon
 
 2015-07-17 08:40:01.217 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSPopoverFrame
 2015-07-17 08:40:01.217 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentShouldCommitEditingNotification, IDESourceCodeDocument
 2015-07-17 08:40:01.219 Xcode[1028:14946] #######  DEBUG >>>  NSUndoManagerCheckpointNotification, DVTUndoManager
 2015-07-17 08:40:01.220 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentWillCloseNotification, IDESourceCodeDocument
 2015-07-17 08:40:01.220 Xcode[1028:14946] #######  DEBUG >>>  IDEEditorDocumentWillClose_ForNavigableItemCoordinatorEyesOnly_Notification, IDESourceCodeDocument
 2015-07-17 08:40:01.221 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.221 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.221 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.221 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.221 Xcode[1028:14946] #######  DEBUG >>>  DVTUndoManagerWasResetNotification, DVTUndoManager
 2015-07-17 08:40:01.224 Xcode[1028:14946] #######  DEBUG >>>  NSUserDefaultsDidChangeNotification, NSUserDefaults
 2015-07-17 08:40:01.229 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.230 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.230 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.230 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.232 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.232 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.233 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.233 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:01.233 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageWillProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.233 Xcode[1028:14946] #######  DEBUG >>>  NSTextStorageDidProcessEditingNotification, DVTTextStorage
 2015-07-17 08:40:01.234 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.241 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.254 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:01.271 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:40:01.297 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:01.306 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, DVTSourceTextView
 2015-07-17 08:40:01.306 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, DVTSourceTextView
 2015-07-17 08:40:01.319 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:01.451 Xcode[1028:14946] #######  DEBUG >>>  DVTSourceExpressionSelectedExpressionDidChangeNotification, IDESourceCodeEditor
 2015-07-17 08:40:01.813 Xcode[1028:14946] #######  DEBUG >>>  DVTWeakInterposerRepresentedObjectIsDeallocatingNotification, DVTWeakInterposer_ProxyHelperReference
 2015-07-17 08:40:01.813 Xcode[1028:14946] #######  DEBUG >>>  DVTWeakInterposerRepresentedObjectIsDeallocatingNotification, DVTWeakInterposer_ProxyHelperReference
 2015-07-17 08:40:01.814 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.814 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.814 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.814 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.831 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.831 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.831 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.831 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.847 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.847 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.847 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.848 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.864 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.865 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.865 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.865 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.882 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.882 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.882 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.882 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.899 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.899 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.899 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.899 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.917 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.917 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.917 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.917 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.934 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.934 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.935 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.935 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.936 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.936 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.936 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.936 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.951 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.951 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.951 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.951 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.971 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.971 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.971 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.971 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:01.985 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:01.985 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:01.985 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:01.986 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.003 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.003 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.003 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.003 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.020 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.020 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.021 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.021 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.040 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.040 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.040 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.040 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.054 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.055 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.055 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.055 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.072 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.072 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.072 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.072 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.088 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.088 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.089 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.089 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.199 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:02.200 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:02.200 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:02.200 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:02.233 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:03.265 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:03.265 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:03.265 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:03.266 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:03.441 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionIsChangingNotification, IDENavigatorOutlineView
 2015-07-17 08:40:03.443 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSVisualEffectView
 2015-07-17 08:40:03.448 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:03.456 Xcode[1028:14946] #######  DEBUG >>>  NSOutlineViewSelectionDidChangeNotification, IDENavigatorOutlineView
 2015-07-17 08:40:03.458 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:03.458 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:03.458 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:03.458 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:03.459 Xcode[1028:14946] #######  DEBUG >>>  NSViewDidUpdateTrackingAreasNotification, NSVisualEffectView
 2015-07-17 08:40:03.459 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:03.460 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:03.460 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:03.460 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:03.460 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:03.460 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:03.461 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:03.461 Xcode[1028:14946] #######  DEBUG >>>  NSViewFrameDidChangeNotification, NSMatrix
 2015-07-17 08:40:03.465 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:03.474 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:03.474 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:03.474 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:03.474 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:03.634 Xcode[1028:14946] #######  DEBUG >>>  IDEWorkspaceDocumentWillWriteStateDataNotification, IDEWorkspaceDocument
 2015-07-17 08:40:04.245 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.245 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.246 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.246 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.262 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.263 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.263 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.263 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.280 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.280 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.280 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.281 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.281 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.282 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.282 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.282 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.297 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.297 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.297 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.297 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.313 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.314 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.314 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.314 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.314 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.315 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.315 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.315 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.315 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.315 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.324 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.325 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.325 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.325 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.325 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.325 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.326 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.326 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.326 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.326 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.331 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.331 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.331 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.331 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.331 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.332 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.332 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.332 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.332 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.332 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.333 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.333 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.333 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.333 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.333 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.334 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.348 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.349 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.349 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.349 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.353 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:04.357 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.357 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.357 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.358 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.366 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.366 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.366 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.367 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.382 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.383 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.383 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.383 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.400 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.400 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.400 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.400 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.403 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:04.406 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.406 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.406 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.406 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.407 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.408 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.408 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.408 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.416 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.417 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.417 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.417 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.417 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.417 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.418 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.418 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.418 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.418 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.419 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.419 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.434 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.434 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.434 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.435 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.451 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.451 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.452 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.452 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.468 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.469 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.469 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.469 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.486 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.486 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.486 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.486 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.510 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.510 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.510 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.510 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.527 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.527 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.527 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.527 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.544 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.544 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.544 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.544 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.560 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.561 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.561 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.561 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.577 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.578 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.578 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.578 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.595 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.595 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.595 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.596 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.613 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.613 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.613 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.614 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.630 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.630 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.630 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.630 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.646 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.647 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.647 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.647 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.663 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.664 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.664 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.664 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.680 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.681 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.681 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.681 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.698 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.698 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.698 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.699 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.715 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.715 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.716 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.716 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.732 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.733 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.733 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.733 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.750 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.750 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.750 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.751 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.768 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillUpdateNotification, IDEApplication
 2015-07-17 08:40:04.768 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.768 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidUpdateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.768 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidUpdateNotification, IDEApplication
 2015-07-17 08:40:04.769 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationWillResignActiveNotification, IDEApplication
 2015-07-17 08:40:04.777 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidResignKeyNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.781 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidResignMainNotification, IDEWorkspaceWindow
 2015-07-17 08:40:04.784 Xcode[1028:14946] #######  DEBUG >>>  NSApplicationDidResignActiveNotification, IDEApplication
 2015-07-17 08:40:04.835 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSThemeFrame
 2015-07-17 08:40:04.867 Xcode[1028:14946] #######  DEBUG >>>  _NSSurfaceShouldSyncNote, NSPopoverFrame
 2015-07-17 08:40:04.870 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidChangeOcclusionStateNotification, _NSPopoverWindow
 2015-07-17 08:40:04.870 Xcode[1028:14946] #######  DEBUG >>>  NSWindowDidChangeOcclusionStateNotification, _NSPopoverWindow

*/