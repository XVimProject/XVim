//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@interface XVimCommandLine : NSView

- (id)init;
- (void)setModeString:(NSString*)string;
- (void)setArgumentString:(NSString*)string;
- (void)errorMessage:(NSString*)string;
- (void)didFrameChanged:(NSNotification*)notification;

- (XVimCommandField*)commandField;

+ (XVimCommandLine*)associateOf:(id)object;
- (void)associateWith:(id)object;
@end
