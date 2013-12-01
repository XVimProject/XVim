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
@synthesize reg;

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
	SEL handler = keyStroke.selector;
	if ([self respondsToSelector:handler]) {
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler];
    }

    if( keyStroke.modifier == 0 ){
        unichar c = keyStroke.character;
        self.reg = [NSString stringWithCharacters:&c length:1];
    }else{
        self.reg = nil;
    }
    return nil;
}

@end

@implementation XVimRecordingRegisterEvaluator
- (XVimEvaluator*)AT{
    self.reg = [[[XVim instance] registerManager] lastExecutedRegister];
    return nil;
}
@end
