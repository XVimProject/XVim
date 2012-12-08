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
}
@end

@implementation XVimRegisterEvaluator
- (id)initWithContext:(XVimEvaluatorContext *)context withWindow:(XVimWindow*)window withParent:(XVimEvaluator*)parent{
    if (self = [super initWithContext:context withWindow:window withParent:parent]) {
	}
	return self;
}


- (void)registerFixed:(NSString*)rname{
    [[XVim instance] setYankRegisterByName:rname];
    [self.context appendArgument:rname];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler){
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler];
    }

    [self registerFixed:[keyStroke toString]];
    return [_parent withNewContext:self.context];
}
	
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    return REGISTER_IGNORE;
}

@end

@implementation XVimRecordingRegisterEvaluator
- (void)registerFixed:(NSString*)rname{
    XVimRegister *xregister = [[XVim instance] findRegister:rname];
    if (xregister && xregister.isReadOnly == NO) {
        [self.window recordIntoRegister:xregister];
    } else {
        [[XVim instance] ringBell];
    }
}

@end
