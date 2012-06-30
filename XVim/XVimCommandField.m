//
//  XVimCommandField.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandField.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"

@interface XVimCommandField() {
	XVimWindow<XVimCommandFieldDelegate>* _delegate;
	BOOL _absorbFocusEvent;
}
@end

@implementation XVimCommandField

- (BOOL)becomeFirstResponder
{
	[self show];
	return YES;
}

- (BOOL)resignFirstResponder
{
	[self hide];
	
	if (!_absorbFocusEvent)
	{
		[_delegate commandFieldLostFocus:self];
	}
	_absorbFocusEvent = NO;
	return YES;
}

- (void)setDelegate:(XVimWindow<XVimCommandFieldDelegate>*)delegate
{
	_delegate = delegate;
}

- (void)absorbFocusEvent
{
	_absorbFocusEvent = YES;
}


- (void)hide
{
	[self setEditable:NO];
	[self setHidden:YES];
}

- (void)show
{
	[self setEditable:YES];
	[self setHidden:NO];
}

- (void)keyDown:(NSEvent*)event
{
	// Redirect to window -> XVimCommandLineEvaluator -> Back to here via handleKeyStroke
	// This is to get macro recording and key mapping support
	[_delegate handleKeyEvent:event];
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window
{
	NSEvent *event = [keyStroke toEvent];
	[super keyDown:event];
}

@end
