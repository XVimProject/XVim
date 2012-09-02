//
//  XVimWindowManager.h
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDESourceCodeEditor;

typedef enum {
    XVIM_EDITOR_MODE_STANDARD
    , XVIM_EDITOR_MODE_GENIUS
    , XVIM_EDITOR_MODE_COMPARISON
} XvimEditorMode;

typedef enum {
    XVIM_RIGHT_HORIZONTAL = 0
    , XVIM_RIGHT_VERTICAL = 1
    , XVIM_BOTTOM_HORIZONTAL = 6
    , XVIM_BOTTOM_VERTICAL = 7
} XvimAssistantLayoutMode;



@interface XVimWindowManager : NSObject
+ (void)createWithEditor:(IDESourceCodeEditor*)editor;
+ (XVimWindowManager*)instance;
- (id)initWithEditor:(IDESourceCodeEditor*)editor;
- (void)addEditorWindow;
- (void)addEditorWindowVertical;
- (void)addEditorWindowHorizontal;
- (void)removeEditorWindow;
- (void)closeAllButActive;
- (void)setHorizontal;
- (void)setVertical;
-(void)jumpToOtherEditor;
-(void)jumpToEditorDown;
-(void)jumpToEditorUp;
-(void)jumpToEditorLeft;
-(void)jumpToEditorRight;
-(void)changeToIssuesNavigator;
-(void)selectNextIssue;
-(void)selectPreviousIssue;
@end

#define XVIM_WINDOWMANAGER ([XVimWindowManager instance])
