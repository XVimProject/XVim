//
//  XVimTextObjectEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"

// This evaluator is waiting for the text object command.
// Text Object is a range of string.
// The simplest one is just "w" which will generate
// text object which represents current insertion point
// to the begining of next word.
// When text object is generated this calls rangeFixed method.
// Subclasses can override rangeFixed to do other operation
// on this range (deletion, e.g.)

// The name "TextObject" may not really good since Vim's text object seems differnet concept
// The name will change to XVimMotionEvaluator

typedef enum _MOTION_TYPE{
    CHARACTERWISE_INCLUSIVE,
    CHARACTERWISE_EXCLUSIVE,
    LINEWISE,
}MOTION_TYPE;

@interface XVimTextObjectEvaluator : XVimNumericEvaluator{
    
@private    
    // New design. (_textObject will be replaced with following 2 variables );
    NSUInteger _motionFrom;
    NSUInteger _motionTo;
    BOOL _inverseMotionType; // switch inclusive/exclusive motion ( set to NO to use default motion type )
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;

// textObjectFixed will be replaced with this method
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to;


@end



    

