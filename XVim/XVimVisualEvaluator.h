//
//  XVimVisualEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "XVimVisualMode.h"

@interface XVimVisualEvaluator : XVimMotionEvaluator {
    // _begin may be greater than _insertion ( in case of backward selection )
    NSUInteger _begin;  // Position Start of the Visual mode
    NSUInteger _insertion; //  Current cursor position
    NSUInteger _selection_begin; // Begining of selection (This is differ from _begin when its MODE_LINE)
    NSUInteger _selection_end;  // End of selection (This is differ from _insertion when its MODE_LINE)
	NSRange _operationRange;
    VISUAL_MODE _mode;
}
- (NSUInteger) insertionPointInWindow:(XVimWindow*)window;

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode;

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode 
			withRange:(NSRange)range; // Range is line numbers if mode == MODE_LINE

- (void)updateSelectionInWindow:(XVimWindow*)window;

@end
