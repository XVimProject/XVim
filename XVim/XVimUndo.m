//
//  XVimUndo.m
//  XVim
//
//  Created by John AppleSeed on 17/11/13.
//
//

#import "XVimUndo.h"
#import "XVimView.h"
#import "XVimBuffer.h"

@interface NSTextView (NSPrivate)
/* Cocoa Internal:
 *   Cocoa seems to call that when -undo is called,
 *   presumably to prevent the view from refreshing.
 */
- (void)_setUndoRedoInProgress:(BOOL)arg1;
@end

@interface NSTextStorage (NSUndo)
/* Cocoa Internal:
 *   Looking at a class dump, this NSUndo category looks intersting
 *   and breaking on it in a debugger shows that it's called to capture
 *   the text being replaced in the undo operation, let's mimic that.
 */
- (id)_undoRedoAttributedSubstringFromRange:(NSRange)arg1;
@end

@implementation XVimUndoOperation {
@protected
    NSUndoManager  *_undoManager;
    NSUInteger      _startIndex;
    NSUInteger      _endIndex;
    /* index 3 * i + 0: initial range
     * index 3 * i + 1: replacement range
     * index 3 * i + 2: text
     */
    NSMutableArray *_values;
}

- (instancetype)initWithIndex:(NSUInteger)index
{
    if ((self = [super init])) {
        _startIndex = index;
        _endIndex   = index;
    }
    return self;
}

- (void)dealloc
{
    [_undoManager release];
    [_values release];
    [super dealloc];
}

- (void)setStartIndex:(NSUInteger)index
{
    if (_startIndex == NSNotFound) {
        _startIndex = index;
    }
}

- (void)setEndIndex:(NSUInteger)index
{
    _endIndex = index;
}

- (void)addUndoRange:(NSRange)range
    replacementRange:(NSRange)replacementRange
              buffer:(XVimBuffer *)buffer
{
    if (!_values) {
        _values = [[NSMutableArray alloc] initWithCapacity:3];
    }
    [_values addObject:[NSValue valueWithRange:range]];
    [_values addObject:[NSValue valueWithRange:replacementRange]];
    [_values addObject:[buffer.textStorage _undoRedoAttributedSubstringFromRange:range]];
}

- (void)_undoOp:(NSUInteger)i textStorage:(NSTextStorage *)ts range:(NSRange)range
{
    NSUInteger index= 3 * i + 2;
    NSAttributedString *oldText = [_values objectAtIndex:index];
    NSAttributedString *newText = [ts _undoRedoAttributedSubstringFromRange:range];

    [ts replaceCharactersInRange:range withAttributedString:oldText];
    [_values replaceObjectAtIndex:index withObject:newText];
}

- (void)undoRedo:(XVimBuffer *)buffer view:(XVimView *)xview
{
    NSTextStorage *ts   = buffer.textStorage;
    NSTextView    *view = xview.textView;
    NSUInteger    count = _values.count / 3;

    [view _setUndoRedoInProgress:YES];
    if (!view || [view shouldChangeTextInRange:NSMakeRange(NSNotFound, 0) replacementString:@""]) {
        [ts beginEditing];
        if ([_undoManager isUndoing]) {
            for (NSUInteger i = count; i-- > 0; ) {
                [self _undoOp:i textStorage:ts range:[[_values objectAtIndex:3 * i + 1] rangeValue]];
            }
        } else {
            for (NSUInteger i = 0; i < count; i ++ ) {
                [self _undoOp:i textStorage:ts range:[[_values objectAtIndex:3 * i + 0] rangeValue]];
            }
        }
        [ts endEditing];
        [self registerForBuffer:buffer];
    }
    NSUInteger index = [_undoManager isUndoing] ? _startIndex : _endIndex;
    if (index != NSNotFound) {
        [xview moveCursorToIndex:index];
    }
    [view _setUndoRedoInProgress:NO];
}

- (void)registerForBuffer:(XVimBuffer *)buffer
{
    _undoManager = [buffer.undoManager retain];
    [_undoManager registerUndoWithTarget:buffer selector:@selector(undoRedo:) object:self];
}

@end
