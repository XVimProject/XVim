//
//  XVimTextView.h
//  XVim
//
//  Created by Suzuki Shuichiro on 9/19/12.
//
//

#import "XVimVisualMode.h"
#import <Foundation/Foundation.h>

/**
 * This is the interface to operate on text view used in XVim.
 * Text views want to communicate with XVim handlers(evaluators) must implement this protocol.
 **/

@protocol XVimTextViewProtocol <NSObject>
@property(readonly) NSUInteger insertionPoint;
@property(readonly) NSUInteger insertionColumn;
@property(readonly) NSUInteger insertionPreservedColumn;
@property(readonly) NSUInteger insertionLine;
@property(readonly) NSUInteger selectionBegin;
@property(readonly) NSUInteger selectionAreaStart;
@property(readonly) NSUInteger selectionAreaEnd;
@property(readonly) VISUAL_MODE selectionMode;
@property(readonly) NSString* string;

- (void)startSelection:(VISUAL_MODE)mode;
- (void)endSelection;
- (void)moveCursor:(NSUInteger)pos;

@end
