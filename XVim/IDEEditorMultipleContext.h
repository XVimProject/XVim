//
//  IDEEditorMultipleContext.h
//  XVim
//
//  Created by Nader Akoury on 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEEditorContext;

@interface IDEEditorMultipleContext : NSObject
- (IDEEditorContext*)selectedEditorContext;
- (void)closeAllEditorContextsKeeping:(id)arg1;
- (void)closeEditorContext:(id)arg1;
- (BOOL)canCloseEditorContexts;
- (id)addEditorContext;
- (void)splitEditorContext:(id)arg1;
- (BOOL)canCreateAdditionalEditorContexts;
- (id)secondEditorContext;
- (id)firstEditorContext;
- (id)editorContexts;
@end