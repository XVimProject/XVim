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

@implementation XVimSourceView(Xcode)

- (DVTSourceTextView*)xview
{
	return (DVTSourceTextView*)[self view];
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

- (IDEEditor*)editor
{
    return (IDEEditor*)[[self xview] delegate];
}

- (NSURL*)documentURL
{
    return [(NSDocument*)[self editor].document fileURL];
}
@end
