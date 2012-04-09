//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimGEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimMotionEvaluator.h"
#import "XVimTildeEvaluator.h"
#import "XVimLowercaseEvaluator.h"
#import "XVimUppercaseEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"

@implementation XVimGEvaluator

- (XVimEvaluator*)d:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)f:(XVimWindow*)window{
    // Does not work correctly.
    // This seems because the when XCode change the content of DVTSourceTextView
    // ( for example when the file shown in the view is changed )
    // it makes the content empty first but does not set selectedRange.
    // This cause assertion is NSTextView+VimMotion's ASSERT_VALID_RANGE_WITH_EOF.
    // One option is change the assertion condition, but I still need to 
    // know more about this to implement robust one.
    //[NSApp sendAction:@selector(openQuickly:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)g:(XVimWindow*)window{
    //TODO: Must deal numeric arg as linenumber
    DVTSourceTextView* view = [window sourceView];
    NSUInteger location = [view nextLine:0 column:0 count:self.repeat - 1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:location Type:LINEWISE inWindow:window];
}

- (XVimEvaluator*)u:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimLowercaseAction alloc] init];
	return [[XVimLowercaseEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimUppercaseAction alloc] init];
	return [[XVimUppercaseEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimTildeAction alloc] init];
	return [[XVimTildeEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)searchCurrentWordInWindow:(XVimWindow*)window forward:(BOOL)forward {
	XVimSearch* searcher = [[XVim instance] searcher];
	
	NSUInteger cursorLocation = [window cursorLocation];
	NSUInteger searchLocation = cursorLocation;
    NSRange found;
    for (NSUInteger i = 0; i < self.repeat && found.location != NSNotFound; ++i){
        found = [searcher searchCurrentWordFrom:searchLocation forward:forward matchWholeWord:NO inWindow:window];
		searchLocation = found.location;
    }
	
	if (![searcher selectSearchResult:found inWindow:window])
	{
		return nil;
	}
    
	return [self _motionFixedFrom:cursorLocation To:found.location Type:CHARACTERWISE_EXCLUSIVE inWindow:window];
}

- (XVimEvaluator*)ASTERISK:(XVimWindow*)window{
	return [self searchCurrentWordInWindow:window forward:YES];
}

- (XVimEvaluator*)NUMBER:(XVimWindow*)window{
	return [self searchCurrentWordInWindow:window forward:YES];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classResponds:[XVimGEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
