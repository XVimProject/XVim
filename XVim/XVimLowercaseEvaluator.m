//
//  XVimLowercaseEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimLowercaseEvaluator.h"
#import "DVTSourceTextView.h"
#import "NSTextView+VimMotion.h"

@implementation XVimLowercaseEvaluator

- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)u:(id)arg {
    if (_repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [self textView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:_repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
	NSTextView *view = [self textView];
	NSRange r = [self getOperationRangeFrom:from To:to Type:type];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}

@end
