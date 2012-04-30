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
#import "XVimInsertEvaluator.h"
#import "XVimMarkMotionEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"

@implementation XVimGActionEvaluator

- (XVimEvaluator*)d:(XVimWindow*)window{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)f:(XVimWindow*)window{
    // Does not work correctly.
    // This seems because the when Xcode change the content of DVTSourceTextView
    // ( for example when the file shown in the view is changed )
    // it makes the content empty first but does not set selectedRange.
    // This cause assertion is NSTextView+VimMotion's ASSERT_VALID_RANGE_WITH_EOF.
    // One option is change the assertion condition, but I still need to 
    // know more about this to implement robust one.
    //[NSApp sendAction:@selector(openQuickly:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)i:(XVimWindow*)window
{
	NSUInteger markLocation = [XVimMarkMotionEvaluator markLocationForMark:@"." inWindow:window];
	if (markLocation == NSNotFound) { return nil; }
	
	XVimSourceView *view = [window sourceView];
	
	NSUInteger insertionPoint = markLocation;
	[view setSelectedRangeWithBoundsCheck:insertionPoint To:insertionPoint];
    if (!([view isEOF:insertionPoint] || [view isNewLine:insertionPoint]))
	{
		[view moveForward];
    } 
	
	return [[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]]];
}

- (XVimEvaluator*)u:(XVimWindow*)window {
	XVimOperatorAction* operatorAction = [[XVimLowercaseAction alloc] init];
	return [[XVimLowercaseEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"u"]
											operatorAction:operatorAction 
												withParent:_parent];
}

- (XVimEvaluator*)U:(XVimWindow*)window {
	XVimOperatorAction* operatorAction = [[XVimUppercaseAction alloc] init];
	return [[XVimUppercaseEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"U"]
											operatorAction:operatorAction 
												withParent:_parent];
}

- (XVimEvaluator*)TILDE:(XVimWindow*)window {
	XVimOperatorAction* operatorAction = [[XVimTildeAction alloc] init];
	return [[XVimTildeEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"~"]
										operatorAction:operatorAction 
											withParent:_parent];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classImplements:[XVimGActionEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
