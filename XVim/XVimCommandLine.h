//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
#import "XVimCommandField.h"

@class XVim;

@interface XVimCommandLine : NSView{
    XVimCommandField* _command;
    NSTextField* _status;
}
@property NSInteger tag;
@property(retain) NSString* mode;
@property(strong) NSString* additionalStatus;

- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view;
- (void)didFrameChanged:(NSNotification*)notification;
- (void)setFocusOnCommandWithFirstLetter:(NSString*)first;

- (id)initWithXVim:(XVim*)xvim;
- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt;

@end
