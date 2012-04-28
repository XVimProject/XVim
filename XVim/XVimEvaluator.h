//
//  XVimEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

// Evaluator classes Hierarchy
/*
XVimEvaluators and its subclasses are the class to handle keyboad input.
Upper class of these evaluator hierarchy implement common process of keyboard input.
For example "motions" such as 'w','b' are handled by XVimMotionEvaluator and this is common parent class for a class
which needs to take a motions as operations. XVimDeleteEvaluator is one of the subclass of XVimMotionEvaluator ( its direct parent is XVimOperatorEvaluator ).
 
XVimEvaluator - Evaluator base
|- XVimMotionArgumentEvaluator 
|- XVimNumericEvaluator - Handles numeric input
     |- XVimMotionEvaluator- Handles motions
          |- XVimNormalEvaluator - Handle normal mode. If XVimTextObject handled motion, this evaluator just move the cursor to the end point of the motion.
 
And Most of the command which takes "Motion" as argument they are derived from XVimMotionEvaluator.

XVimMotionEvaluator
|- XVimOperatorEvaluator
|    |- XVimVisualEvaluator - Handles Visual mode (Move cursor as per motion and expand the selection)
|    |- XVimDeleteEvaluator - Handles 'd' and 'c' command.
|    .... and so on. 
|
|- XVimNormalEvaluator
|- XVimVisualEvaluator
... And so on.

An evaluator which takes argument to determine the motion ( like 'f' ) use XVimMotionArgumentEvaluator as its parent class.

*/

#import "XVimRegister.h"
#import "XVimMode.h"
#import "XVimEvaluatorContext.h"

@class XVimMotionEvaluator;
@class XVimKeyStroke;
@class XVimKeymap;
@class XVimWindow;
@class DVTSourceTextView;
@class XVimRegister;
@protocol XVimKeymapProvider;

@class XVimEvaluatorContext;

@interface XVimEvaluator : NSObject

- (id)initWithContext:(XVimEvaluatorContext*)context;

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window;

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister;

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider;

- (void)becameHandlerInWindow:(XVimWindow*)window;

- (void)willEndHandlerInWindow:(XVimWindow*)window;

- (void)didEndHandlerInWindow:(XVimWindow*)window;

- (XVimEvaluator*)defaultNextEvaluatorInWindow:(XVimWindow*)window;

- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event inWindow:(XVimWindow*)window;

- (NSRange)restrictSelectedRange:(NSRange)range inWindow:(XVimWindow*)window;

- (NSUInteger)insertionPointInWindow:(XVimWindow*)window;

- (void)drawRect:(NSRect)rect inWindow:(XVimWindow*)window;

- (BOOL)shouldDrawInsertionPointInWindow:(XVimWindow*)window;

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color inWindow:(XVimWindow*)window heightRatio:(float)heightRatio;

- (NSString*)modeString;

- (BOOL)isRelatedTo:(XVimEvaluator*)other;

////////////////////////////////////////////////
// Context convenience functions

// Normally argumentString, but can be overridden
- (NSString*)argumentDisplayString;

// Returns the current stack of arguments (eg. "a10d...")
- (NSString*)argumentString;

// Returns the context yank register if any
- (XVimRegister*)yankRegister;

// Returns the context numeric arguments multiplied together
- (NSUInteger)numericArg;

// Returns the context
- (XVimEvaluatorContext*)context;

// Equivalent to [[self context] copy]
- (XVimEvaluatorContext*)contextCopy;

// Clears the context and returns self, useful for escaping from operators
- (XVimEvaluator*)withNewContext;

// Returns self with the passed context
- (XVimEvaluator*)withNewContext:(XVimEvaluatorContext*)context;

@end


