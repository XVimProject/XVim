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

- (XVimEvaluator*)d{
    [NSApp sendAction:@selector(jumpToDefinition:) to:nil from:self];
    return nil;
}

- (XVimEvaluator*)f{
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

- (XVimEvaluator*)i{
	NSUInteger markLocation = [XVimMarkMotionEvaluator markLocationForMark:@"." inWindow:self.window];
	if (markLocation == NSNotFound) { return nil; }
	
	XVimSourceView *view = self.sourceView;
	
	NSUInteger insertionPoint = markLocation;
	[view setSelectedRangeWithBoundsCheck:insertionPoint To:insertionPoint];
    if (!([view isEOF:insertionPoint] || [view isNewLine:insertionPoint])){
		[view moveForward];
    } 
	
	return [[[XVimInsertEvaluator alloc] initWithContext:[XVimEvaluatorContext contextWithNumericArg:[self numericArg]] withWindow:self.window] autorelease];
}

- (XVimEvaluator*)u{
	return [[[XVimLowercaseEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"u"] withWindow:self.window] autorelease];
}

- (XVimEvaluator*)U{
	return [[[XVimUppercaseEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"U"] withWindow:self.window] autorelease];
}

- (XVimEvaluator*)TILDE{
	return [[[XVimTildeEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"~"] withWindow:self.window] autorelease];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if ([keyStroke classImplements:[XVimGActionEvaluator class]]){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end
