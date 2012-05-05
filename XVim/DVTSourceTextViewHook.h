//
//  DVTSourceTextView.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DVTSourceTextView;
@class XVimStatusLine;

@interface DVTSourceTextViewHook : NSObject
+ (void)hook;
@end
