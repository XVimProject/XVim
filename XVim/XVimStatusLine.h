//
//  XVimStatusLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define XVIM_STATUSLINE_TAG 1210

@interface XVimStatusLine : NSView
- (void)layoutStatus:(NSView*)container;
@property  NSInteger tag;
@end
