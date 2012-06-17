//
//  XVimSourceView+Xcode.h
//  XVim
//
//  Created by Tomas Lundell on 30/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimSourceView.h"

/**
 
 Xcode category on XVimSourceView
 
 Adds Xcode specific functionality to XVimSourceView.
 
 Code that doesn't rely on Xcode should be in either XVimSourceView
 or XVimSourceView+Vim.

 **/

@class DVTSourceTextView, IDESourceCodeEditor, IDEEditorContext, IDEEditorMultipleContext, IDEWorkspaceWindowController, IDEWorkspaceWindow;

@interface XVimSourceView(Xcode)

@property (weak) DVTSourceTextView *xview;
@property (weak) IDESourceCodeEditor *sourceCodeEditor;
@property (weak) IDEEditorContext *editorContext;
@property (weak) IDEEditorMultipleContext *editorMultipleContext;
@property (weak) IDEWorkspaceWindow *window;
@property (weak) IDEWorkspaceWindowController *windowController;
// Indentation
- (void)shiftLeft;
- (void)shiftRight;
- (void)indentCharacterRange:(NSRange)range;

// Returns the number of lines in the document
- (NSUInteger)numberOfLines;

// Returns the column number of character @ index
- (NSUInteger)columnNumber:(NSUInteger)index;

// Returns the current line number
- (long long)currentLineNumber;

// Calls parent key down
- (void)keyDown:(NSEvent*)event;

// Calls parent
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;

//
- (void)updateInsertionPointStateAndRestartTimer;

// Completions
- (void)hideCompletions;

// Selects the next tab-complete area
- (void)selectNextPlaceholder;
- (void)selectPreviousPlaceholder;

// Sets the wrapline option
- (void)setWrapsLines:(BOOL)wraps;

-(void)splitEditor:(BOOL)vertical;
-(void)jumpToAlternateFile;
-(void)closeOtherEditors;
-(void)takeFocus;
@end
