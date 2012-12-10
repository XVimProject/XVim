//
//  XVimDeleteEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimDeleteEvaluator.h"
#import "XVimInsertEvaluator.h"
#import "XVimWindow.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimSourceView+Xcode.h"
#import "XVimTextObjectEvaluator.h"
#import "Logger.h"

@interface XVimDeleteEvaluator() {
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
           withWindow:(XVimWindow *)window
           withParent:(XVimEvaluator*)parent
insertModeAtCompletion:(BOOL)insertModeAtCompletion{
	if (self = [super initWithContext:context withWindow:window withParent:parent]){
		self->_insertModeAtCompletion = insertModeAtCompletion;
	}
	return self;
}

- (XVimEvaluator*)c{
    if( !_insertModeAtCompletion ){
        return nil;  // 'dc' does nothing
    }
    // 'cc' should obey the repeat specifier
    // '3cc' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
}

- (XVimEvaluator*)d{
    if( _insertModeAtCompletion ){
        return nil;  // 'cd' does nothing
    }
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m];
}

- (XVimEvaluator*)j{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:m];
}

- (XVimEvaluator*)k{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:m];
}

-(XVimEvaluator*)motionFixed:(XVimMotion*)motion{
    if (_insertModeAtCompletion == TRUE) {
        // Do not repeat the insert, that is how vim works so for
        // example 'c3wWord<ESC>' results in Word not WordWordWord
        [[self sourceView] change:motion];
        return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init] withWindow:self.window];
    }else{
        [[self sourceView] delete:motion];
    }
    return nil;
}

- (XVimEvaluator*)onChildComplete:(XVimEvaluator *)childEvaluator{
    if( [childEvaluator isKindOfClass:[XVimTextObjectEvaluator class]] ){
        MOTION_OPTION opt = ((XVimTextObjectEvaluator*)childEvaluator).inner ? TEXTOBJECT_INNER : MOTION_OPTION_NONE;
        XVimMotion* m = XVIM_MAKE_MOTION(((XVimTextObjectEvaluator*)childEvaluator).textobject, CHARACTERWISE_INCLUSIVE, opt, [self numericArg]);
        [[self sourceView] delete:m];
    }
    return nil;
}
@end
