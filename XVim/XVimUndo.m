//
//  XVimUndo.m
//  XVim
//
//  Created by John AppleSeed on 17/11/13.
//
//

#import "XVimUndo.h"
#import "NSTextView+VimOperation.h"
#import "XVimBuffer.h"

@implementation XVimUndoCursorPositionOperation {
    NSUndoManager   *_undoManager;
    XVimPosition     _pos;
}

- (instancetype)initWithPosition:(XVimPosition)pos
                     undoManager:(NSUndoManager *)undoManager
{
    if ((self = [super init])) {
        _pos           = pos;
        _undoManager   = [undoManager retain];
    }
    return self;
}

- (void)dealloc
{
    [_undoManager release];
    [super dealloc];
}

- (void)undoRedo:(XVimBuffer *)buffer
{
    NSTextStorage *text = buffer.textStorage;

    for (NSLayoutManager *mgr in text.layoutManagers) {
        NSTextView *view = mgr.firstTextView;

        if (view.textStorage == text) {
            [view xvim_moveToPosition:_pos];
            return;
        }
    }
}

@end
