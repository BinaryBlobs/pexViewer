//
//  NSObject+Blocks.m
//  BB-Gfx
//
//  Created by Hugh on 12/28/13.
//  Copyright (c) 2013 Binary Blobs. All rights reserved.
//

#import "NSObject+Blocks.h"

@implementation NSObject (Blocks)

+ (void)performBlock:(void (^)())block
{
    block();
}

+ (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay
{
    if(delay <= 0)
    {
        block();
    }
    else
    {
        void (^block_)() = [block copy]; // autorelease this if you're not using ARC
        [self performSelector:@selector(performBlock:) withObject:block_ afterDelay:delay];
    }
}

@end