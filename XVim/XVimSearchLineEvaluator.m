//
//  XVimSearchEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearchLineEvaluator.h"
#import "XVimMotionEvaluator.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimCharacterSearch.h"
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

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window
{
	XVimCharacterSearch *charSearcher = [[XVim instance] characterSearcher];
	
	unichar key = keyStroke.keyCode;
    NSString *searchChar = [NSString stringWithCharacters:&key length:1];
    [charSearcher setSearchCharacter:searchChar backward:!self.forward previous:self.previous];

    NSTextView *view = (NSTextView*)[window superview];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [charSearcher searchNextCharacterFrom:location inWindow:window];
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
        [window ringBell];
    }else{
        MOTION_TYPE type=CHARACTERWISE_INCLUSIVE;
        if( !_forward ){
            // If the last search was forward "semicolon" is forward search and this is the case its CHARACTERWISE_EXCLUSIVE
            type = CHARACTERWISE_EXCLUSIVE;
        }
        self.performedSearch = YES;
        return [self _motionFixedFrom:[view selectedRange].location To:location Type:type inWindow:window]; 
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