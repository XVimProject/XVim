//
//  XVimEqualEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/5/2012
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEqualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "DVTSourceTextView.h"
#import "DVTFoldingTextStorage.h"
#import "XVimMotionEvaluator.h"
#import "Logger.h"

@implementation XVimEqualEvaluator

- (XVimEvaluator*)EQUAL:(id)arg{
    if (self.repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [self textView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}

@end

@implementation XVimEqualAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
	DVTSourceTextView* view = [self textView];
	[view selectOperationTargetFrom:from To:to Type:type];
	[view copy:self];
	// Indent
	[[view textStorage] indentCharacterRange: [view selectedRange] undoManager:[view undoManager]];
	[view setSelectedRange:NSMakeRange(from<to?from:to, 0)];
	return nil;
}

@end
