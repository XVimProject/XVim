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
#import "XVimKeyStroke.h"
#import "Logger.h"

@implementation XVimGEvaluator
- (XVimEvaluator*)g:(id)arg{
    //TODO: Must deal numeric arg as linenumber
    DVTSourceTextView* view = [self textView];
    NSUInteger location = [view nextLine:0 column:0 count:self.repeat - 1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:location Type:LINEWISE];
}

- (XVimEvaluator*)ASTERISK:(id)arg{
    NSRange found;
    for (NSUInteger i = 0; i < self.repeat && found.location != NSNotFound; ++i){
        found = [self.xvim.searcher searchCurrentWord:YES matchWholeWord:NO];
    }

    if (NSNotFound == found.location){
        [self.xvim statusMessage:[NSString stringWithFormat: @"Cannot find '%@'",self.xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }

    //Move cursor and show the found string
    NSRange begin = [[self textView] selectedRange];
    [[self textView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[self textView] scrollToCursor];
    [[self textView] showFindIndicatorForRange:found];
    
    return [self _motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimEvaluator*)NUMBER:(id)arg{
    NSRange found;
    for (NSUInteger i = 0; i < self.repeat && found.location != NSNotFound; ++i){
        found = [self.xvim.searcher searchCurrentWord:NO matchWholeWord:NO];
    }
    
    if (NSNotFound == found.location){
        [self.xvim statusMessage:[NSString stringWithFormat: @"Cannot find '%@'",self.xvim.searcher.lastSearchString] ringBell:TRUE];
        return nil;
    }
    
    //Move cursor and show the found string
    NSRange begin = [[self textView] selectedRange];
    [[self textView] setSelectedRange:NSMakeRange(found.location, 0)];
    [[self textView] scrollToCursor];
    [[self textView] showFindIndicatorForRange:found];
    
    return [self _motionFixedFrom:begin.location To:found.location Type:CHARACTERWISE_EXCLUSIVE];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classResponds:[XVimGEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end