//
//  XVimTildeEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTildeEvaluator.h"
#import "XVimWindow.h"
#import "DVTSourceTextView.h"
#import "NSTextView+VimMotion.h"

@implementation XVimTildeEvaluator

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
    if (self.repeat < 1) 
        return nil;
    
    DVTSourceTextView* view = [window sourceView];
    NSUInteger end = [view nextLine:[view selectedRange].location column:0 count:self.repeat-1 option:MOTION_OPTION_NONE];
    return [self _motionFixedFrom:[view selectedRange].location To:end Type:LINEWISE inWindow:window];
}

@end

@implementation XVimTildeAction
-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window
{
	NSTextView *view = [window sourceView];
	NSRange r = [view getOperationRangeFrom:from To:to Type:type];
	[view toggleCaseForRange:r];
	[view setSelectedRange:NSMakeRange(r.location, 0)];
    return nil;
}
@end