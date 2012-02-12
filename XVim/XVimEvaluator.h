//
//  XVimEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//


@class XVim;

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


// This evaluator is waiting for the text object command.
// Text Object is a range of string.
// The simplest one is just "w" which will generate
// text object which represents current insertion point
// to the begining of next word.
// When text object is generated this calls rangeFixed method.
// Subclasses can override rangeFiexd to do other operation
// on this range (deletion, e.g.)
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


// This evaluates events in Normal (COMMAND) mode
// This is the root evaluator.
// Every command and mode transition starts from this object.
// If XVimTextObjectEvaluator returns valid range object
// move the cusor to the position
@interface XVimNormalEvaluator : XVimTextObjectEvaluator
@end

@interface XVimSearchLineEvaluator : XVimEvaluator{
    NSUInteger _repeat;
}
@property BOOL forward;
@end

@interface XVimDeleteEvaluator : XVimTextObjectEvaluator{
@private
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat;
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
}

- (id)initWithRepeat:(NSUInteger)repeat;
@end

@interface XVimVisualEvaluator : XVimTextObjectEvaluator{
    NSUInteger _origin;
    NSUInteger _end;
}
@property BOOL lineSelection;
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
   
