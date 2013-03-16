//
//  XVimOperatorEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/18/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimOperatorEvaluator.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "XVimOperatorAction.h"
#import "XVimTextObjectEvaluator.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimKeymapProvider.h"

@interface XVimOperatorEvaluator() {
	XVimEvaluator *_parent;
}
@end

// TODO: Maybe need to override b,B,w,W operation (See older implementation)

@implementation XVimOperatorEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context withWindow:window withParent:(XVimEvaluator*)parent{
	if (self = [super initWithContext:context withWindow:window]){
		_parent = [parent retain];
	}
	return self;
}

- (void)drawRect:(NSRect)rect{
	return [_parent drawRect:rect];
}

- (void)dealloc
{
    [_parent release];
    [super dealloc];
}

- (BOOL)shouldDrawInsertionPoint{
	return [_parent shouldDrawInsertionPoint];
}

- (float)insertionPointHeightRatio{
    return 0.5;
}

- (NSString*)modeString{
	return [_parent modeString];
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other{
	return [super isRelatedTo:other] || other == _parent;
}

- (XVimEvaluator*)defaultNextEvaluator{
    return [_parent withNewContext];
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider{
	return [keymapProvider keymapForMode:MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)a{
	return [[[XVimTextObjectEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"a"] withWindow:self.window withParent:_parent inner:NO] autorelease];
}

// TODO: There used to be "b:" and "B:" methods here. Take a look how they have been.

- (XVimEvaluator*)i{
    return [[[XVimTextObjectEvaluator alloc] initWithContext:[[self contextCopy] appendArgument:@"i"] withWindow:self.window withParent:_parent inner:YES] autorelease];
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if([keyStroke instanceResponds:self] || keyStroke.isNumeric){
        TRACE_LOG(@"REGISTER_APPEND");
        return REGISTER_APPEND;
    }
    
    TRACE_LOG(@"REGISTER_IGNORE");
    return REGISTER_IGNORE;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    // TODO FIXME:
	//return [self->_operatorAction motionFixedFrom:from To:to Type:type inWindow:window];
    return nil;
}
@end
