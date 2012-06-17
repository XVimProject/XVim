//
//  XVimSourceView+Xcode.m
//  XVim
//
//  Created by Tomas Lundell on 30/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimSourceView+Xcode.h"
#import "DVTSourceTextViewHook.h"
#import "DVTKit.h"
#import "IDEKit.h"
#import "IDESourceEditor.h"


@interface EditorContextContext : NSObject {
    NSUInteger contextIdx;
    IDEEditorMultipleContext* multipleContext;
    IDEWorkspaceWindow* window;
}
@end

@implementation XVimSourceView(Xcode)

@dynamic xview;
@dynamic sourceCodeEditor;
@dynamic editorContext;
@dynamic editorMultipleContext;
@dynamic window;
@dynamic windowController;

- (DVTSourceTextView*)xview
{
	return (DVTSourceTextView*)[self view];
}
-(IDESourceCodeEditor*)sourceCodeEditor
{
    return (IDESourceCodeEditor*)[[self xview] delegate];
}
-(IDEEditorContext*)editorContext
{
    return self.sourceCodeEditor.editorContext;
}
-(IDEEditorMultipleContext*)editorMultipleContext
{
    return self.editorContext.multipleContext;
}
-(IDEWorkspaceWindow*)window
{
    return (IDEWorkspaceWindow*)[self.xview window];
}
-(IDEWorkspaceWindowController*)windowController
{
    return (IDEWorkspaceWindowController*)[self.window windowController];
}

- (NSUInteger)columnNumber:(NSUInteger)index
{
	DVTFoldingTextStorage *textStorage = (DVTFoldingTextStorage*)[[self xview] textStorage];
	return (NSUInteger)[textStorage columnForPositionConvertingTabs:index];
}

- (long long)currentLineNumber
{
	return [[self xview] _currentLineNumber];
}

- (NSUInteger)numberOfLines{
    DVTFoldingTextStorage* storage = [[self xview] textStorage];
    return [storage numberOfLines]; //  This is DVTSourceTextStorage method
}

- (void)shiftLeft
{
	[[self xview] shiftLeft:self];
}

- (void)shiftRight
{
	[[self xview] shiftRight:self];
}

- (void)indentCharacterRange:(NSRange)range
{
	[[[self xview] textStorage] indentCharacterRange:range undoManager:[[self xview] undoManager]];
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color
{
	[[self xview] _drawInsertionPointInRect_:rect color:color];
}

- (void)hideCompletions
{
	[[[self xview] completionController] hideCompletions];
}

- (void)selectNextPlaceholder
{
	[[self xview] selectNextPlaceholder:self];
}

- (void)selectPreviousPlaceholder
{
	[[self xview] selectPreviousPlaceholder:self];
}

- (void)keyDown:(NSEvent*)event
{
	[[self xview] keyDown_:event];
}

- (void)setWrapsLines:(BOOL)wraps
{
	[[self xview] setWrapsLines:wraps];
}

- (void)updateInsertionPointStateAndRestartTimer
{
	[[self xview] updateInsertionPointStateAndRestartTimer:YES];
}

-(void)splitEditor:(BOOL)vertical
{
    [ self.editorContext openInAdjacentEditorWithAlternate:self ];
}

-(void)jumpToAlternateFile
{
    [ NSApp sendAction:@selector(jumpToNextCounterpart:) to:nil from:self.view];
}

-(void)closeOtherEditors
{
    [self.editorMultipleContext closeAllEditorContextsKeeping:self.editorContext];
}

-(void)takeFocus
{
    [self.window makeFirstResponder:self.view ];
}

@end
