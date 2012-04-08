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

- (XVimEvaluator*)u:(XVim*)xvim {
    if (self.repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [xvim sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE XVim:xvim];
}

@end

@implementation XVimLowercaseAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type XVim:(XVim*)xvim
{
	NSTextView *view = [xvim sourceView];
	NSRange r = [view getOperationRangeFrom:from To:to Type:type];
	[view lowercaseRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
	return nil;
}
@end

