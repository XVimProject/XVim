//
//  XVimMarkSetEvaluator.m
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMarkSetEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"

@implementation XVimMarkSetEvaluator

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window {
    NSString* keyStr = [keyStroke toSelectorString];
	if ([keyStr length] != 1) {
        return [self defaultNextEvaluatorInWindow:window];
    }
    unichar c = [keyStr characterAtIndex:0];
    if (! (((c>='a' && c<='z')) || ((c>='A' && c<='Z'))) ) {
        return [self defaultNextEvaluatorInWindow:window];
    }
	NSRange r = [[window sourceView] selectedRange];
	NSValue *v =[NSValue valueWithRange:r];
	[[window getLocalMarks] setValue:v forKey:keyStr];
    
    return [self defaultNextEvaluatorInWindow:window];
}

@end
