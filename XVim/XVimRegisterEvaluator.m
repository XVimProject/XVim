//
//  XVimRegisterEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimRegisterEvaluator.h"
#import "XVimNormalEvaluator.h"
#import "XVimRegister.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "Logger.h"

@interface XVimRegisterEvaluator() {
	OnSelectRegister _onComplete;
}
@end

@implementation XVimRegisterEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimEvaluator*)parent
		 completion:(OnSelectRegister)onComplete
{
	if (self = [super initWithContext:context parent:parent])
	{
		_parent = parent;
		_onComplete = [onComplete copy];
	}
	return self;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke 
			  inWindow:(XVimWindow*)window
{
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler){
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler withObject:window];
    }

	return _onComplete([keyStroke toSelectorString], [self contextCopy]);
}
	
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    return REGISTER_IGNORE;
}

@end