//
//  XVimSearchEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearchLineEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimKeyStroke.h"

// Search Line 
@interface XVimSearchLineEvaluator()
@property (nonatomic) BOOL performedSearch;
@end

@implementation XVimSearchLineEvaluator
@synthesize forward = _forward;
@synthesize previous = _previous;
@synthesize performedSearch = _performedSearch;

- (id)initWithMotionEvaluator:(XVimMotionEvaluator*)evaluator withRepeat:(NSUInteger)rep{
    self = [super initWithMotionEvaluator:evaluator withRepeat:rep];
    if( self ){
        _performedSearch = NO;
    }
    return self;
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke ofXVim:(XVim *)xvim{
	unichar key = keyStroke.key;
    NSString *searchChar = [NSString stringWithCharacters:&key length:1];
    [xvim setSearchCharacter:searchChar backward:!self.forward previous:self.previous];

    NSTextView *view = (NSTextView*)[xvim superview];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [xvim searchCharacterNext:location];
        if (location == NSNotFound || ++i >= self.repeat){
            break;
        }

        if (self.previous){
            if (self.forward){
                location += 1;
            }else{
                location -=1;
            }
        }
    }

    if (location == NSNotFound) {
        [xvim ringBell];
    }else{
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        if( !_forward ){
            // If the last search was forward "semicolon" is forward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        self.performedSearch = YES;
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type]; 
    }

    return nil;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*) keyStroke inRegister:(XVimRegister*)xregister{
    if (self.performedSearch){
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:keyStroke inRegister:xregister];
}

@end