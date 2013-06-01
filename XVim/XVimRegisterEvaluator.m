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

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke{
	SEL handler = [keyStroke selectorForInstance:self];
	if (handler){
		TRACE_LOG(@"Calling SELECTOR %@", NSStringFromSelector(handler));
        return [self performSelector:handler];
    }

    if( keyStroke.modifier == 0 ){
        unichar c = keyStroke.character;
        self.reg = [[XVim instance] findRegister:[NSString stringWithCharacters:&c length:1]];
    }else{
        self.reg = nil;
    }
    return nil;
}
	
- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    return REGISTER_IGNORE;
}

@end

@implementation XVimRecordingRegisterEvaluator
- (XVimEvaluator*)AT{
    self.reg = [[XVim instance] lastPlaybackRegister];
    return nil;
}
@end
