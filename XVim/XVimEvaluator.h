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
#import "XVim.h"

@class XVimMotionEvaluator;
@class XVimKeyStroke;
@class XVimKeymap;
@class DVTSourceTextView;

typedef enum {
  MARKOPERATOR_SET,
  MARKOPERATOR_MOVETO,
  MARKOPERATOR_MOVETOSTARTOFLINE
} XVimMarkOperator;


@interface XVimEvaluator : NSObject
- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke ofXVim:(XVim*)xvim;
- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps;
- (XVimEvaluator*)defaultNextEvaluator;
// Made into a property so it can be set 
@property (weak) XVim *xvim;
@property (readonly) DVTSourceTextView *textView;
@property (readonly) NSUInteger insertionPoint;

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister;
- (XVIM_MODE)becameHandler:(XVim*)xvim;
@end
