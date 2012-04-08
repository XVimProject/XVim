//
//  DVTCompletionController.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DVTCompletionController : NSObject
- (id)debugStateString;
- (BOOL)showInfoPanelForSelectedCompletion;
- (id)attributesForCompletionAtCharacterIndex:(unsigned long long)arg1 effectiveRange:(struct _NSRange *)arg2;
- (BOOL)_textViewShouldInsertTab;
- (BOOL)_textViewShouldHandleCancel;
- (BOOL)_textViewShouldHandleComplete;
- (BOOL)_textViewShouldHandlePreviousCompletion;
- (BOOL)_textViewShouldHandleNextCompletion;
- (void)_applicationWillDispatchAction:(SEL)arg1;
- (BOOL)textViewShouldSetMarkedText:(id)arg1 selectedRange:(struct _NSRange)arg2;
- (BOOL)textViewShouldChangeTextInRange:(struct _NSRange)arg1 replacementString:(id)arg2;
- (BOOL)textViewShouldPerformAction:(SEL)arg1;
- (void)_textViewDidScroll:(id)arg1;
- (void)_textViewWillUndoRedo:(id)arg1;
- (void)textViewDidInsertText;
- (BOOL)textViewShouldInsertText:(id)arg1;
- (void)_textViewTextDidChange:(id)arg1;
- (void)textViewSelectionChanging;
- (void)_dismissAndInvalidateCurrentSession;
- (void)_hideCompletionsWithoutInvalidatingWithReason:(int)arg1;
- (void)hideCompletions;
- (BOOL)acceptCurrentCompletion;
- (BOOL)_showCompletionsAtCursorLocationExplicitly:(BOOL)arg1;
- (BOOL)showCompletionsAtCursorLocation;
- (void)setSessionInProgress:(BOOL)arg1;
- (BOOL)sessionInProgress;
@end
