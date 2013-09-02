//
//  IDEEditorArea+XVim.h
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEKit.h"
#import "XVimCommandLine.h"

/*
 * This is the extension of IDEEditorArea class in Xcode.
 * The IDEEditorArea is the area including source text view and debugging area.
 * See IDEKit.h to refer original IDEEditorArea class.
 */
@interface IDEEditorArea (XVim)
- (XVimWindow*)xvimWindow;
- (XVimCommandLine*)commandLine;
- (NSView*)textViewArea;
- (void)setupCommandLine;
- (void)teardownCommandLine;
@end
