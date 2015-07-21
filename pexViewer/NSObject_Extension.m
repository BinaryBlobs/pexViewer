//
//  NSObject_Extension.m
//  pexViewer
//
//  Created by Hugh on 7/14/15.
//  Copyright (c) 2015 Binary Blobs. All rights reserved.
//


#import "NSObject_Extension.h"
#import "pexViewerPlugIn.h"

@implementation NSObject (Xcode_Plugin_Template_Extension)

//============================================================================================================================================

+ (void)pluginDidLoad:(NSBundle *)plugin
{
    static dispatch_once_t onceToken;
    NSString *currentApplicationName = [[NSBundle mainBundle] infoDictionary][@"CFBundleName"];
    
    if ([currentApplicationName isEqual:@"Xcode"])
    {
        dispatch_once(&onceToken, ^
        {
            sharedPlugin = [[pexViewerPlugIn alloc] initWithBundle:plugin];
        });
    }
}
//============================================================================================================================================

@end
