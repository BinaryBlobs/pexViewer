//
//  NSObject+NSObject_Blocks.h
//  BB-Gfx
//
//  Created by Hugh on 12/28/13.
//  Copyright (c) 2013 Binary Blobs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (Blocks)

+ (void)performBlock:(void (^)())block afterDelay:(NSTimeInterval)delay;

@end