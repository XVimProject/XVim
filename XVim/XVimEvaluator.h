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

*/

#import "XVimRegister.h"
#import "XVimMode.h"
#import "XVimTextViewProtocol.h"

@class XVimMotionEvaluator;
@class XVimKeyStroke;
@class XVimKeymap;
@class XVimWindow;
@class DVTSourceTextView;
@class XVimRegister;
@class XVimSourceView;
@protocol XVimKeymapProvider;

@interface XVimEvaluator : NSObject <XVimTextViewDelegate>
@property(strong) XVimWindow* window;
@property(strong) XVimEvaluator* parent;
@property NSUInteger numericArg;
@property(strong) NSMutableString* argumentString;
@property(strong) XVimRegister* yankRegister;
@property SEL onChildCompleteHandler;

- (id)initWithWindow:(XVimWindow*)window;

+ (XVimEvaluator*)invalidEvaluator;

/**
 * About eval: method.
 * This method handles key input.
 * You usually do not need to override this method.
 * Default implementation tries to find a method named same as key input and calls it
 * and returns its return value directly.
 * For example if 'a' is an input it tries to call a: method and the method must return XVimEvaluator* .
 * The meaning of evaluator returned from each method is explained below.
 * So what derived classes of XVimEvaluators should do is adding methods to handle key input.
 * If it does not find any matched method to call it returns Invalud Evaluator explained below.
 *
 * The return value is one of followings
 *  - Next Evaluator
 *  - self
 *  - nil
 *  - Invalid Evaluator
 *
 * If this method returns any valid evaluator other than self it will be handled as a next
 * evaluator and the next key input will be redirected to the returned evaluator.
 * If this method returns self it means next evaluator is itself and next key input is still
 * passed to this evaluator.
 * If it returns nil it means this evaluator finished its task and the parent evaluator
 * (which is the evaluator previously created this evaluator and returned it as a next evaluator)
 * will be notified that its child evaluator finished its task via onChildComplete: method.
 * If it returns invalid evaluator (which is [XVimEvaluator invalidEvaluator]) it means
 * the key input to this evaluator is invalid and cancel all the input observed so far (which is almost
 * same as inputing "ESC" )
 **/
- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke;

/**
 * This method is called when "next evaluator" returned by eval: method completed its task.
 * @return Next evaluator. If its nil it means that this evaluator finished its task and
 *         onChildComplete: of parent evaluator will be called with this evaluator.
 **/
- (XVimEvaluator*)onChildComplete:(XVimEvaluator*)childEvaluator;


/**
 * This is called when an evaluator became next handler.
 * Next key input will be redirected to this evaluator.
 * You can do some setup before handling next key input.
 *
 * YOU MUST CALL [super becameHandler] when you override this.
 **/
- (void)becameHandler;

/**
 * This is called when an evaluator has been finished its task and evicted from stack evaluatorhandler.
 * This happens when you return next evaluator as "nil" or other evaluators.
 * You can do some tearing down before handling next key input.
 *
 * YOU MUST CALL [super didEndHandler] when you override this.
 **/
- (void)didEndHandler;
- (XVimEvaluator*)defaultNextEvaluator;
- (XVimEvaluator*)handleMouseEvent:(NSEvent*)event;
- (NSRange)restrictSelectedRange:(NSRange)range;
- (void)drawRect:(NSRect)rect;
- (BOOL)shouldDrawInsertionPoint;
- (float)insertionPointHeightRatio;
- (float)insertionPointWidthRatio;
- (float)insertionPointAlphaRatio;

- (NSString*)modeString;
- (BOOL)isRelatedTo:(XVimEvaluator*)other;

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister;
- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider;

- (XVimSourceView*)sourceView;

- (void)textYanked:(NSString*)yankedText withType:(TEXT_TYPE)type inView:(id)view;
- (void)textDeleted:(NSString*)deletedText withType:(TEXT_TYPE)type inView:(id)view;

////////////////////////////////////////////////
// Context convenience functions

// Normally argumentString, but can be overridden
- (NSString*)argumentDisplayString;

// Returns the context yank register if any
- (XVimRegister*)yankRegister;

// Returns the context numeric arguments multiplied together
- (NSUInteger)numericArg;
@end



