//
//  XVimYankEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimYankEvaluator.h"
#import "XVimWindow.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "Logger.h"
#import "XVim.h"

@implementation XVimYankEvaluator

- (XVimEvaluator*)y:(XVimWindow*)window{
    // 'yy' should obey the repeat specifier 
    // e.g., '3yy' should yank/copy the current line and the two lines below it
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self motionFixed:m inWindow:window];
    
}

- (XVimEvaluator*)motionFixed:(XVimMotion *)motion inWindow:(XVimWindow *)window{
    XVimSourceView* view = [window sourceView];
    [view yank:motion];
    return nil;
    
}
@end


@implementation XVimYankAction

-(id)initWithYankRegister:(XVimRegister*)xregister {
	if (self = [super init]) {
		_yankRegister = xregister;
	}
	return self;
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type inWindow:(XVimWindow*)window {
    XVimSourceView* view = [window sourceView];
    [view selectOperationTargetFrom:from To:to Type:type];
    [view copyText];
    //[[XVim instance] onDeleteOrYank:_yankRegister];

    [view setSelectedRange:NSMakeRange(from, 0)];
    return nil;
}
@end