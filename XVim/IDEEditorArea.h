//
//  IDEEditorArea.h
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEEditorContext;
@class IDEEditorModeViewController;

@interface IDEEditorArea : NSViewController
- (int)editorMode;
- (IDEEditorContext*)primaryEditorContext;
- (IDEEditorContext*)lastActiveEditorContext;
- (IDEEditorModeViewController*)editorModeViewController;
- (void)viewDidInstall;
- (void)viewDidInstall_;
@end
