//
//  XVimCommandEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@class XVimHistoryHandler;

typedef XVimEvaluator* (^OnCompleteHandler) (NSString* command);
typedef void (^OnKeyPressHandler) (NSString* command);

@interface XVimCommandLineEvaluator : XVimEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimEvaluator*)parent 
		 firstLetter:(NSString*)firstLetter 
			 history:(XVimHistoryHandler*)history
		  completion:(OnCompleteHandler)completeHandler
		  onKeyPress:(OnKeyPressHandler)keyPressHandler;

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window;

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister;

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider;

- (void)becameHandlerInWindow:(XVimWindow*)window;

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window;

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event inWindow:(XVimWindow*)window;

- (NSRange)restrictSelectedRange:(NSRange)range inWindow:(XVimWindow*)window;

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window;

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window;

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window;

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio;

- (NSString*)modeString;

@end
