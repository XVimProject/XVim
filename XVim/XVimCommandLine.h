//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@class XVimWindow;

#define XVIM_CMDLINE_TAG 1208
@interface XVimCommandLine : NSView
@property NSInteger tag;

- (id)init;

- (void)setModeString:(NSString*)string;
- (void)setStaticString:(NSString*)string;
- (void)errorMessage:(NSString*)string;
- (void)didFrameChanged:(NSNotification*)notification;

- (XVimCommandField*)commandField;

@end
