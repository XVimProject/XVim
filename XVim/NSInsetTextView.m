//
//  NSInsetTextView.m
//  XVim
//
//  Created by Tomas Lundell on 5/05/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NSInsetTextView.h"

@implementation NSInsetTextView
@synthesize inset = _inset;

- (NSPoint)textContainerOrigin {
    NSPoint origin = [super textContainerOrigin];
    NSPoint newOrigin = NSMakePoint(origin.x + _inset.width, origin.y + _inset.height);
    return newOrigin;
}

@end
