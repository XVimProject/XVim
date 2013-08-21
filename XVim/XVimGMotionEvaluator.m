//
//  XVimGEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimGMotionEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimMotionOption.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimSearch.h"
#import "Logger.h"

@implementation XVimGMotionEvaluator

- (XVimEvaluator*)g{
    self.motion = XVIM_MAKE_MOTION(MOTION_LINENUMBER, LINEWISE, MOTION_OPTION_NONE, 1);
    self.motion.line = self.numericArg;
    return nil;
}

- (XVimEvaluator*)searchCurrentWord:(BOOL)forward {
    //TODO: Must be moved to XVimSearch.m
    //TODO: Must be unified to the same method in XVimMotionEvaluator
	XVimSearch* searcher = [[XVim instance] searcher];
	NSUInteger cursorLocation = [self.window.sourceView insertionPoint];
	NSUInteger searchLocation = cursorLocation;
    NSRange found = NSMakeRange(0, 0);
    for (NSUInteger i = 0; i < [self numericArg] && found.location != NSNotFound; ++i){
        found = [searcher searchCurrentWordFrom:searchLocation forward:forward matchWholeWord:NO inWindow:self.window];
		searchLocation = found.location;
    }
	
	if (found.location == NSNotFound) {
        self.motion = nil;
	}else{
        self.motion = XVIM_MAKE_MOTION(MOTION_POSITION, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
        self.motion.position = found.location;
    }
    
    return nil;
}

- (XVimEvaluator*)ASTERISK{
	return [self searchCurrentWord:YES];
}

- (XVimEvaluator*)NUMBER{
	return [self searchCurrentWord:NO];
}

@end
