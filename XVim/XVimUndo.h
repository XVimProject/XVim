//
//  XVimUndo.h
//  XVim
//
//  Created by John AppleSeed on 17/11/13.
//
//

#import <Foundation/Foundation.h>
#import "XVimDefs.h"

@class XVimBuffer;

@protocol XVimUndoing

- (void)undoRedo:(XVimBuffer *)text;

@end

@interface XVimUndoCursorPositionOperation : NSObject<XVimUndoing>

- (instancetype)initWithPosition:(XVimPosition)pos
                     undoManager:(NSUndoManager *)undoManager;

@end
