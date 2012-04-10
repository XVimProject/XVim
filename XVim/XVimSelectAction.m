//
//  XVimSelectAction.m
//  XVim
//
//  Created by Tomas Lundell on 10/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimSelectAction.h"
#import "XVimVisualEvaluator.h"
#import "XVimWindow.h"
#import "DVTSourceTextView.h"
#import "NSTextView+VimMotion.h"

@implementation XVimSelectAction

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from 
							   To:(NSUInteger)to 
							 Type:(MOTION_TYPE)type 
						 inWindow:(XVimWindow*)window
{
	NSTextView *view = [window sourceView];
	NSRange r = [view getOperationRangeFrom:from To:to Type:type];
	return [[XVimVisualEvaluator alloc] initWithMode:MODE_CHARACTER withRange:r];
}

@end
