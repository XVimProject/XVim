//
//  XVimEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

// Evaluator classes Hierarchy
/*
XVimEvaluator - Evaluator base
|- XVimNumericEvaluator - Handles numeric input
|- XVimTextObject - Handles motions (As I commented in the code, the name is not really proper)
|- XVimNormalEvaluator - Handle normal mode. If XVimTextObject handled motion, this evaluator just move the cursor to the end point of the motion.
 
And Most of the command which takes "Motion" as argument they are derived from XVimTextObject.

XVimTextObject
|- XVimVisualEvaluator - Handles Visual mode (Move cursor as per motion and expand the selection)
|- XVimDeleteEvaluator - Handles 'd' command.

... And so on.


An evaluator which takes argument to determine the motion ( like 'f' ) I'm currently implementing 
another structure. 
(Current implementation of XVimSearchLine evaluator can not be used from like 'd' command )
*/

@class XVim;
@class XVimTextObjectEvaluator;

typedef enum {
  MARKOPERATOR_SET,
  MARKOPERATOR_MOVETO,
  MARKOPERATOR_MOVETOSTARTOFLINE
} XVimMarkOperator;


@interface XVimEvaluator : NSObject{
@private
    NSTextView* _textView;
    XVim* _xvim;
}
+ (NSString*) keyStringFromKeyEvent:(NSEvent*)event;
- (XVimEvaluator*)eval:(NSEvent*) event ofXVim:(XVim*)xvim;
- (XVimEvaluator*)defaultNextEvaluator;
- (NSTextView*)textView;
- (XVim*)xvim;
@end

// This evaluator is waiting for number input.
@interface XVimNumericEvaluator : XVimEvaluator{
    NSUInteger _numericArg;
    BOOL _numericMode;
}
- (NSUInteger)numericArg;
- (void)resetNumericArg;
@end

// This is base class of an evaluator which takes arguments to determing the motion such as 'f','F'.
// When the subclass fix the motion it must call motionFixedFrom:To: method.
@interface XVimMotionArgumentEvaluator : XVimEvaluator{
@private
    XVimTextObjectEvaluator* _motionEvaluator;
    NSUInteger _repeat;
}
- (id)initWithMotionEvaluator:(XVimTextObjectEvaluator*)evaluator withRepeat:(NSUInteger)repeat;
@end


// This evaluator is collecting a mark name as part of the 'm{mark-name-letter}' command
@interface XVimLocalMarkEvaluator : XVimEvaluator{
@private
     XVimMarkOperator _markOperator;
     XVim *_xvimTarget;
}
- (id)initWithMarkOperator:(XVimMarkOperator)markOperator xvimTarget:(XVim *)xvimTarget;
@end





