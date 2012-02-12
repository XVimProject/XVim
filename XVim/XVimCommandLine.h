//
//  XVimCommandLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/10/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <AppKit/AppKit.h>
@class XVimCommandField;

@interface XVimCommandLine : NSView  <NSTextFieldDelegate>{
    XVimCommandField* _command;
    NSTextField* _status;
}
@property NSInteger tag;
@property(retain) id xvim;
@property(retain) NSString* mode;

- (void)layoutDVTSourceTextScrollViewSubviews:(NSScrollView*) view;
- (void)didFrameChanged:(NSNotification*)notification;
- (void)setFocusOnCommandWithFirstLetter:(NSString*)first;


@end
