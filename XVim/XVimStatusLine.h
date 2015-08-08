//
//  XVimStatusLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

extern NSString* const XVimStatusLineIDEEditorKey;

@class IDEEditor;

@interface XVimStatusLine : NSView
@property (weak,nonatomic) IDEEditor* editor;
- (void)layoutStatus:(NSView*)container;

+ (XVimStatusLine*)associateOf:(id)object;
- (void)associateWith:(id)object;
@end
