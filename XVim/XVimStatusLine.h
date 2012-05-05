//
//  XVimStatusLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XVimStatusLine : NSView
- (void)layoutStatus:(NSView*)container;

+ (XVimStatusLine*)associateOf:(id)object;
- (void)associateWith:(id)object;
@end
