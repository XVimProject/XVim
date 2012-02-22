//
//  XVimEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//


@class XVim;

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

// This evaluator is collecting a mark name as part of the 'm{mark-name-letter}' command
@interface XVimLocalMarkEvaluator : XVimEvaluator{
@private
     XVimMarkOperator _markOperator;
     XVim *_xvimTarget;
}
- (id)initWithMarkOperator:(XVimMarkOperator)markOperator xvimTarget:(XVim *)xvimTarget;
@end

// This evaluator is waiting for the text object command.
// Text Object is a range of string.
// The simplest one is just "w" which will generate
// text object which represents current insertion point
// to the begining of next word.
// When text object is generated this calls rangeFixed method.
// Subclasses can override rangeFiexd to do other operation
// on this range (deletion, e.g.)

// The name "TextObject" may not really good since Vim's text object seems differnet concept
@interface XVimTextObjectEvaluator : XVimNumericEvaluator{
@private    
    NSRange _textObject;
    NSUInteger _destLocation; // end point of the text object. This is neccesary since we can't determine which is the start and end point of the range(text object).
    id _textObjectFixedHandlerObject;
    SEL _textObjectFixedHandler;
}
- (XVimEvaluator*)textObjectFixed;
- (NSRange)textObject;
- (void)setTextObject:(NSRange)textObject;
- (NSUInteger) destLocation;
- (void)setTextObjectFixed:(id)obj handler:(SEL)sel;
@end





@interface XVimDeleteEvaluator : XVimTextObjectEvaluator{
@private
    BOOL _insertModeAtCompletion;
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion;
@end

@interface XVimYankEvaluator : XVimTextObjectEvaluator{
@private
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat;
@end

@interface XVimInsertEvaluator : XVimEvaluator{
    NSUInteger _repeat;
    BOOL _insertedEventsAbort;
    NSMutableArray* _insertedEvents;
    BOOL _oneCharMode;
}

- (id)initWithRepeat:(NSUInteger)repeat;
- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat;
@end

@interface XVimShiftEvaluator : XVimTextObjectEvaluator{
    NSUInteger _repeat;
}
@property BOOL unshift;
- (id) initWithRepeat:(NSUInteger)repeat;
@end
// Evaluates 'g' command
@interface XVimgEvaluator : XVimTextObjectEvaluator{
}
@end
// Evaluates 'r' command
@interface XVimrEvaluator : XVimTextObjectEvaluator{
}
@end
