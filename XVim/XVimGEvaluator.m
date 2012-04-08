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
#import "Logger.h"

@implementation XVimGEvaluator

- (XVimEvaluator*)d:(XVim*)xvim{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)f:(XVim*)xvim{
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

- (XVimEvaluator*)g:(XVim*)xvim{
    //TODO: Must deal numeric arg as linenumber
    DVTSourceTextView* view = [xvim sourceView];
    NSUInteger location = [view nextLine:0 column:0 count:self.repeat - 1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:location Type:LINEWISE XVim:xvim];
}

- (XVimEvaluator*)u:(XVim*)xvim {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimLowercaseAction alloc] init];
	return [[XVimLowercaseEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)U:(XVim*)xvim {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimUppercaseAction alloc] init];
	return [[XVimUppercaseEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)TILDE:(XVim*)xvim {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimTildeAction alloc] init];
	return [[XVimTildeEvaluator alloc] initWithOperatorAction:operatorAction repeat:repeat];
}

- (XVimEvaluator*)ASTERISK:(XVim*)xvim{
    NSRange found;
    for (NSUInteger i = 0; i < self.repeat && found.location != NSNotFound; ++i){
        found = [xvim.searcher searchCurrentWord:YES matchWholeWord:NO];
    }

    if (NSNotFound == found.location){
        [xvim errorMessage:[NSString stringWithFormat: @"Cannot find '%@'", xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }

    //Move cursor and show the found string
    NSRange begin = [[xvim sourceView] selectedRange];
    [[xvim sourceView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[xvim sourceView] scrollToCursor];
    [[xvim sourceView] showFindIndicatorForRange:found];
    
    return [self _motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimEvaluator*)NUMBER:(XVim*)xvim{
    NSRange found;
    for (NSUInteger i = 0; i < self.repeat && found.location != NSNotFound; ++i){
        found = [xvim.searcher searchCurrentWord:NO matchWholeWord:NO];
    }
    
    if (NSNotFound == found.location){
        [xvim errorMessage:[NSString stringWithFormat: @"Cannot find '%@'", xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }
    
    //Move cursor and show the found string
    NSRange begin = [[xvim sourceView] selectedRange];
    [[xvim sourceView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[xvim sourceView] scrollToCursor];
    [[xvim sourceView] showFindIndicatorForRange:found];
    
    return [self _motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE XVim:xvim];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classResponds:[XVimGEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
