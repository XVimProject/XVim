//
//  XVimVisualEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimMotionEvaluator.h"
#import "XVimVisualMode.h"

// TODO:
// insertionPoint in Visual mode is different from NSTextView's point obtained from selectedRange.
// Evaluator should not keep these values but keep it in DVTSourceTextView+XVim extension.
// They only rely on their interface to handle them.
@interface XVimVisualEvaluator : XVimMotionEvaluator {
	NSRange _operationRange;
    VISUAL_MODE _mode;
}

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode;

- (id)initWithContext:(XVimEvaluatorContext*)context
				 mode:(VISUAL_MODE)mode 
			withRange:(NSRange)range; // Range is line numbers if mode == MODE_LINE


@end
