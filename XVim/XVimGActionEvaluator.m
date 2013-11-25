//
//  XVimGActionEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimJoinEvaluator.h"
#import "XVimGActionEvaluator.h"
#import "XVimSwapCharsEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimMark.h"
#import "XVimMarks.h"
#import "XVimVisualEvaluator.h"
#import "NSTextStorage+VimOperation.h"
#import "XVimView.h"

@implementation XVimGActionEvaluator

- (XVimEvaluator*)d{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)f{
    // Does not work correctly.
    // This seems because the when Xcode change the content of DVTSourceTextView
    // ( for example when the file shown in the view is changed )
    // it makes the content empty first but does not set selectedRange.
    // This cause assertion is NSTextView+VimMotion's ASSERT_VALID_RANGE_WITH_EOF.
    // One option is change the assertion condition, but I still need to 
    // know more about this to implement robust one.
    //[NSApp sendAction:@selector(openQuickly:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)i{
    XVimMark *mark = [[XVim instance].marks markForName:@"^" forDocument:self.window.currentBuffer.document];
    XVimInsertionPoint mode = XVIM_INSERT_DEFAULT;
    XVimBuffer *buffer = self.window.currentBuffer;

	if (mark.line != NSNotFound) {
        NSUInteger newPos = [buffer indexOfLineNumber:mark.line column:mark.column];
        if (NSNotFound != newPos) {
            XVimMotion *m = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, 0);

            m.position = newPos;
            
            // set the position before the jump
            XVimMark *cur_mark = [[[XVimMark alloc] init] autorelease];
            XVimView *xview = self.currentView;
            XVimPosition pos = xview.insertionPosition;
            cur_mark.line = pos.line;
            cur_mark.column = pos.column;
            cur_mark.document = buffer.document.fileURL.path;
            if (nil != mark.document) {
                [[XVim instance].marks setMark:cur_mark forName:@"'"];
            }
            [xview moveCursorWithMotion:m];
            mode = XVIM_INSERT_APPEND;
        }
    }
	return [[[XVimInsertEvaluator alloc] initWithWindow:self.window oneCharMode:NO mode:mode] autorelease];
}

- (XVimEvaluator*)J{
    XVimJoinEvaluator* eval = [[[XVimJoinEvaluator alloc] initWithWindow:self.window addSpace:NO] autorelease];
    return [eval executeOperationWithMotion:XVIM_MAKE_MOTION(MOTION_NONE, CHARACTERWISE_EXCLUSIVE, MOPT_NONE, self.numericArg)];
}

- (XVimEvaluator*)u{
    [self.argumentString appendString:@"u"];
	return [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_LOWER] autorelease];
}

- (XVimEvaluator*)U{
    [self.argumentString appendString:@"U"];
	return [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_UPPER] autorelease];
}

- (XVimEvaluator*)v{
    // Select previous visual selection
    return [[[XVimVisualEvaluator alloc] initWithLastVisualStateWithWindow:self.window] autorelease];
}

- (XVimEvaluator*)QUESTION{
    [self.argumentString appendString:@"?"];
	return [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_ROT13] autorelease];
}

- (XVimEvaluator*)TILDE{
    [self.argumentString appendString:@"~"];
	return [[[XVimSwapCharsEvaluator alloc] initWithWindow:self.window mode:XVIM_BUFFER_SWAP_CASE] autorelease];
}

@end
