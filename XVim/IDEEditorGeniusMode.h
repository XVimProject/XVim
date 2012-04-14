//
//  IDEEditorGeniusMode.h
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDEEditorMultipleContext.h"
#import "IDEEditorModeViewController.h"

@interface IDEEditorGeniusMode : IDEEditorModeViewController
- (void)removeAssistantEditor;
- (BOOL)canRemoveAssistantEditor;
- (id)addNewAssistantEditor;
- (BOOL)canAddNewAssistantEditor;
- (void)addAssistantEditor;
- (BOOL)canAddAssistantEditor;
- (void)setAssistantEditorsLayout:(int)arg1;
- (BOOL)canChangeAssistantEditorsLayout;
- (void)_closeAllSplitsKeeping:(id)arg1;
- (IDEEditorMultipleContext*)alternateEditorMultipleContext;;
- (id)_geniusCategoryForEditorContext:(id)arg1;
- (void)_setDefaultGeniusCategoryForEditorContext:(id)arg1;
- (id)_manualCategoryNavigableItemForEditorContext:(id)arg1;
- (void)_primitiveSetGeniusCategory:(id)arg1 forEditorContext:(id)arg2;
- (void)_setGeniusRootNavigableItem:(id)arg1 forEditorContext:(id)arg2;
- (id)editorContexts;
@property BOOL splitsVertical;
@end