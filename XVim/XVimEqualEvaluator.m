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
#import "XVimWindow.h"
#import "Logger.h"
#import "XVim.h"

@implementation XVimEqualEvaluator

- (XVimEvaluator*)EQUAL:(XVimWindow*)window{
    if ([self numericArg] < 1) 
        return nil;
    
    DVTSourceTextView* view = [window sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:[self numericArg]-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

@end

@implementation XVimEqualAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
	DVTSourceTextView* view = [window sourceView];
	[view selectOperationTargetFrom:from To:to Type:type];
	[view copy:self];
    [[XVim instance] onDeleteOrYank];

	// Indent
	[[view textStorage] indentCharacterRange: [view selectedRange] undoManager:[view undoManager]];
	[view setSelectedRange:NSMakeRange(from<to?from:to, 0)];
	return nil;
}

@end
