//
//  XVimEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//


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
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to;
@end


// This evaluator is collecting a mark name as part of the 'm{mark-name-letter}' command
@interface XVimLocalMarkEvaluator : XVimEvaluator{
@private
     XVimMarkOperator _markOperator;
     XVim *_xvimTarget;
}
- (id)initWithMarkOperator:(XVimMarkOperator)markOperator xvimTarget:(XVim *)xvimTarget;
@end





