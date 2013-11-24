//
//  XVimUndo.h
//  XVim
//
//  Created by John AppleSeed on 17/11/13.
//
//

#import <Foundation/Foundation.h>

@class XVimBuffer;
@class XVimView;

@interface XVimUndoOperation : NSObject

- (instancetype)initWithIndex:(NSUInteger)index;

- (void)undoRedo:(XVimBuffer *)buffer view:(XVimView *)view;

- (void)addUndoRange:(NSRange)range
    replacementRange:(NSRange)replacementRange
              buffer:(XVimBuffer *)buffer;

- (void)setStartIndex:(NSUInteger)index;
- (void)setEndIndex:(NSUInteger)index;

- (void)registerForBuffer:(XVimBuffer *)buffer;

@end