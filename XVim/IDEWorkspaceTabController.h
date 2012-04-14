//
//  IDEWorkspaceTabController.h
//  XVim
//
//  Created by Nader Akoury 4/14/12
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEEditorArea;

@interface IDEWorkspaceTabController : NSObject
- (IDEEditorArea*) editorArea;

// Assistant editor related
+ (int)defaultAssistantEditorsLayout;
+ (void)setDefaultAssistantEditorsLayout:(int)arg1;
- (int)assistantEditorsLayout;
- (void)removeAssistantEditor:(id)arg1;
- (void)addAssistantEditor:(id)arg1;
- (void)changeToAssistantLayout_BH:(id)arg1;
- (void)changeToAssistantLayout_BV:(id)arg1;
- (void)changeToAssistantLayout_TH:(id)arg1;
- (void)changeToAssistantLayout_TV:(id)arg1;
- (void)changeToAssistantLayout_LH:(id)arg1;
- (void)changeToAssistantLayout_LV:(id)arg1;
- (void)changeToAssistantLayout_RH:(id)arg1;
- (void)changeToAssistantLayout_RV:(id)arg1;

- (void)changeToGeniusEditor:(id)arg1;
- (void)changeToVersionEditor:(id)arg1;
- (void)changeToStandardEditor:(id)arg1;
@end