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
#import "XVimSourceView.h"

@implementation XVimMarkSetEvaluator

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
    NSString* keyStr = [keyStroke toSelectorString];
	if ([keyStr length] != 1) {
        return [self defaultNextEvaluator];
    }
    unichar c = [keyStr characterAtIndex:0];
    if (! (((c>='a' && c<='z')) || ((c>='A' && c<='Z')) || c == '`' || c == '\'' ) ) {
        return [self defaultNextEvaluator];
    }
	NSRange r = [[self sourceView] selectedRange];
	NSValue *v =[NSValue valueWithRange:r];
    if( c == '`' ){
        // Both m' and m` use internally a ' mark like original vim.
        keyStr = @"'";
    }
	[[self.window getLocalMarks] setValue:v forKey:keyStr];
    
    return [self defaultNextEvaluator];
}

@end
