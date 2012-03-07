//
//  XVimMotionEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEvaluator.h"


// This evaluator handles motions.
// The simplest one is just "w" which will generate
// motion which represents current insertion point
// to the begining of next word.
// When motion is generated motionFixedFrom:To:Type: method is called.
// Make subclass of this to implement operation on which takes motions as argument (deletion,yank...and so on.)

@interface XVimMotionEvaluator : XVimNumericEvaluator{
    
@private    
    NSUInteger _motionFrom;
    NSUInteger _motionTo;
    BOOL _inverseMotionType; // switch inclusive/exclusive motion ( set to NO to use default motion type )
}

// Override this method to implement operations on motions.
// THere could be from < to (This means backwards motion)
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type;



@end



    

