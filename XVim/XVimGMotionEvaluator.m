//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimGMotionEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMotionOption.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"

@implementation XVimGMotionEvaluator

- (XVimEvaluator*)g{
    //TODO: Must deal numeric arg as linenumber
    XVimSourceView* view = [self.window sourceView];
    NSUInteger location = [view nextLine:0 column:0 count:[self numericArg] - 1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:location Type:LINEWISE];
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward {
	XVimSearch* searcher = [[XVim instance] searcher];
	
	NSUInteger cursorLocation = [self.window insertionPoint];
	NSUInteger searchLocation = cursorLocation;
    NSRange found = NSMakeRange(0, 0);
    for (NSUInteger i = 0; i < [self numericArg] && found.location != NSNotFound; ++i){
        found = [searcher searchCurrentWordFrom:searchLocation forward:forward matchWholeWord:NO inWindow:self.window];
		searchLocation = found.location;
    }
	
	if (![searcher selectSearchResult:found inWindow:self.window]) {
		return nil;
	}
    
	return [self _motionFixedFrom:cursorLocation To:found.location Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)ASTERISK:(XVimWindow*)window{
	return [self searchCurrentWord:YES];
}

- (XVimEvaluator*)NUMBER:(XVimWindow*)window{
	return [self searchCurrentWord:YES];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classResponds:[XVimGMotionEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
