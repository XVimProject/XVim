//
//  XVimInsertEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@interface XVimInsertEvaluator : XVimEvaluator{
    NSUInteger _repeat;
    BOOL _insertedEventsAbort;
    NSMutableArray* _insertedEvents;
    BOOL _oneCharMode;
}

- (id)initWithRepeat:(NSUInteger)repeat ofXVim:(XVim*)xvim;
- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat ofXVim:(XVim*)xvim;
@end
