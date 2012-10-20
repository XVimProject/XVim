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
@dynamic selectedLineRange;

- (DVTSourceTextView*)xview
{
	return (DVTSourceTextView*)[self view];
}
- (DVTFoldingTextStorage*)xTextStorage
{
	return (DVTFoldingTextStorage*)[[self xview] textStorage];
}

- (NSUInteger)columnNumber:(NSUInteger)index
{
	return (NSUInteger)[[self xTextStorage] columnForPositionConvertingTabs:index];
}

- (long long)currentLineNumber
{
	return [[self xview] _currentLineNumber];
}

- (NSUInteger)numberOfLines{
    return [[self xTextStorage] numberOfLines]; //  This is DVTSourceTextStorage method
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
	[[self xTextStorage] indentCharacterRange:range undoManager:[[self xview] undoManager]];
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


-(NSRange)selectedLineRange
{
    return [ [self xTextStorage] lineRangeForCharacterRange:self.selectedRange ];
}

-(void)setSelectedLineRange:(NSRange)selectedLineRange
{
    if (selectedLineRange.location >= [ self numberOfLines ])
    {
        selectedLineRange.location = MAX(0,[ self numberOfLines ]-1);
    }
    if ((selectedLineRange.location + selectedLineRange.length) > [ self numberOfLines])
    {
        selectedLineRange.length = ([self numberOfLines] - selectedLineRange.location);
    }
    NSRange charRange = [[self xTextStorage] characterRangeForLineRange:selectedLineRange];
    [ [ self xview ] setSelectedRange:charRange];
}


-(NSURL*)documentURL
{
    return [(NSDocument*)((IDEEditor*)[[ self xview] delegate]).document fileURL];
}
@end
