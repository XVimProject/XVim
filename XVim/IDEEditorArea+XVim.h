//
//  IDEEditorArea+XVim.h
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEKit.h"

@class XVimWindow;
@class XVimCommandLine;

/*
 * This is the extension of IDEEditorArea class in Xcode.
 * The IDEEditorArea is the area including source text view and debugging area.
 * See IDEKit.h to refer original IDEEditorArea class.
 */
@interface IDEEditorArea (XVim)

@property (nonatomic, readonly) XVimWindow *xvim_window;
+ (void)xvim_initialize;
- (XVimCommandLine*)xvim_commandline;
- (id)xvim_initWithNibName:(NSString*)name bundle:(NSBundle*)bundle;
- (void)xvim__setEditorModeViewControllerWithPrimaryEditorContext:(id)arg1;

@end
