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
#import "Logger.h"

@interface XVimDeleteEvaluator() {
	BOOL _insertModeAtCompletion;
}
@end

@implementation XVimDeleteEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*)operatorAction 
				  withParent:(XVimEvaluator*)parent
	  insertModeAtCompletion:(BOOL)insertModeAtCompletion
{
	if (self = [super initWithContext:context operatorAction:operatorAction withParent:parent]){
		self->_insertModeAtCompletion = insertModeAtCompletion;
	}
	return self;
}

- (XVimEvaluator*)c:(XVimWindow*)window {
    if( !_insertModeAtCompletion ){
        return nil;  // 'dc' does nothing
    }
    // 'cc' should obey the repeat specifier
    // '3cc' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m inWindow:window];
}

- (XVimEvaluator*)d:(XVimWindow*)window{
    if( _insertModeAtCompletion ){
        return nil;  // 'cd' does nothing
    }
    // 'dd' should obey the repeat specifier
    // '3dd' should delete/cut the current line and the 2 lines below it
    
    if ([self numericArg] < 1) 
        return nil;
    
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]-1);
    return [self _motionFixed:m inWindow:window];
}

- (XVimEvaluator*)j:(XVimWindow*)window{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_FORWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:m inWindow:window];
}

- (XVimEvaluator*)k:(XVimWindow*)window{
    XVimMotion* m = XVIM_MAKE_MOTION(MOTION_LINE_BACKWARD, LINEWISE, MOTION_OPTION_NONE, [self numericArg]);
    return [self _motionFixed:m inWindow:window];
}

-(XVimEvaluator*)motionFixed:(XVimMotion*)motion inWindow:(XVimWindow*)window {
    
    if (_insertModeAtCompletion == TRUE) {
        // Do not repeat the insert, that is how vim works so for
        // example 'c3wWord<ESC>' results in Word not WordWordWord
        [[window sourceView] change:motion];
        return [[XVimInsertEvaluator alloc] initWithContext:[[XVimEvaluatorContext alloc] init]];
    }else{
        [[window sourceView] delete:motion];
    }
    return nil;
}

@end
