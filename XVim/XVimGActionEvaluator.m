//
//  XVimGActionEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimGActionEvaluator.h"
#import "XVimTildeEvaluator.h"
#import "XVimLowercaseEvaluator.h"
#import "XVimUppercaseEvaluator.h"
#import "XVimKeyStroke.h"

@implementation XVimGActionEvaluator

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

- (XVimEvaluator*)u:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimLowercaseAction alloc] init];
	return [[XVimLowercaseEvaluator alloc] initWithOperatorAction:operatorAction 
													   withParent:_motionEvaluator
														   repeat:repeat];
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimUppercaseAction alloc] init];
	return [[XVimUppercaseEvaluator alloc] initWithOperatorAction:operatorAction 
													   withParent:_motionEvaluator
														   repeat:repeat];
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	NSUInteger repeat = [self repeat];
	XVimOperatorAction* operatorAction = [[XVimTildeAction alloc] init];
	return [[XVimTildeEvaluator alloc] initWithOperatorAction:operatorAction 
												   withParent:_motionEvaluator
													   repeat:repeat];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classImplements:[XVimGActionEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
