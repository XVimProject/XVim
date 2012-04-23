//
//  IDEEditorModeViewController.h
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDEEditorArea.h"

@interface IDEEditorModeViewController : NSViewController
+ (long long)version;
+ (void)configureStateSavingObjectPersistenceByName:(id)arg1;
+ (id)stateSavingIdentifiers;
//@property IDEEditorContext *selectedAlternateEditorContext; // @synthesize selectedAlternateEditorContext=_selectedAlternateEditorContext;
//@property IDEEditorContext *primaryEditorContext; // @synthesize primaryEditorContext=_primaryEditorContext;
@property(assign) IDEEditorArea *editorArea; // @synthesize editorArea=_editorArea;
- (void)editorContext:(id)arg1 editorStateRepositoryDidChange:(id)arg2;
- (void)commitStateToDictionary:(id)arg1;
- (void)revertStateWithDictionary:(id)arg1;
- (void)_setPersistentRepresentation:(id)arg1 forIdentifier:(id)arg2;
- (id)_persistentRepresentationForIdentifier:(id)arg1;
- (void)_setPersistentRepresentation:(id)arg1;
- (id)_persistentRepresentation;
- (void)_stampEditorLayoutConfiguration:(id)arg1 forIdentifier:(id)arg2;
- (id)_liftEditorLayoutConfigurationForIdentifier:(id)arg1;
- (void)_stampEditorLayoutConfiguration:(id)arg1;
- (id)_liftEditorLayoutConfiguration;
- (BOOL)_getStateSavingStateDictionaries:(id *)arg1 selected:(id *)arg2 geometry:(id *)arg3 forPersistentRepresentation:(id)arg4;
- (id)_persistentRepresentationForStateSavingStateDictionaries:(id)arg1 selected:(id)arg2 geometry:(id)arg3;
- (BOOL)_getEditorHistoryStacks:(id *)arg1 selected:(id *)arg2 geometry:(id *)arg3 forEditorLayoutConfiguration:(id)arg4;
- (id)_editorLayoutConfigurationForEditorHistoryStacks:(id)arg1 selected:(id)arg2 geometry:(id)arg3;
- (BOOL)_getItems:(id *)arg1 itemsKey:(id)arg2 selected:(id *)arg3 geometry:(id *)arg4 inConfigurationDictionary:(id)arg5;
- (id)_configurationDictionaryWithItems:(id)arg1 itemsKey:(id)arg2 selected:(id)arg3 geometry:(id)arg4;
- (id)_stealPrimaryEditorContext;
- (id)editorContexts;
- (BOOL)openEditorOpenSpecifier:(id)arg1 editorContext:(id)arg2;
- (BOOL)openEditorHistoryItem:(id)arg1 editorContext:(id)arg2;
@property(readonly) struct CGSize minimumContentViewFrameSize;
- (BOOL)canCreateSplitForNavigationHUD;
- (void)resetEditor;
- (BOOL)canResetEditor;
- (void)removeAssistantEditor;
- (id)addNewAssistantEditor;
- (BOOL)canAddNewAssistantEditor;
- (BOOL)canRemoveAssistantEditor;
- (void)addAssistantEditor;
- (BOOL)canAddAssistantEditor;
- (void)setAssistantEditorsLayout:(int)arg1;
- (BOOL)canChangeAssistantEditorsLayout;
- (id)_initWithPrimaryEditorContext:(id)arg1;
@end
