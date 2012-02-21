//
//  XVimSearchEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearchLineEvaluator.h"
#import "XVim.h"


// Search Line 
@implementation XVimSearchLineEvaluator
@synthesize forward;

- (id) initWithRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent *)event ofXVim:(XVim *)xvim{
    NSString* str = [event characters];
    NSTextView* view = [xvim sourceView];
    NSRange original = [view selectedRange];
    NSRange result = original;
    NSRange findRange;
    if( forward ){
        for( NSUInteger i = 0 ; i < _repeat; i++ ){
            if( result.location != NSNotFound ){
                [view setSelectedRange:NSMakeRange(result.location,0)];
                [view moveToEndOfLineAndModifySelection:self];
                findRange = [view selectedRange];
                findRange.location++;
            }
            else{
                break;
            }
            result = [[view string] rangeOfString:str options:0 range:findRange];
        }
    }
    else{
        for( NSUInteger i = 0 ; i < _repeat; i++ ){
            if( result.location != NSNotFound ){
                [view setSelectedRange:NSMakeRange(result.location,0)];
                [view moveToBeginningOfLineAndModifySelection:self];
                findRange = [view selectedRange];
            }
            else{
                break;
            }
            result = [[view string] rangeOfString:str options:NSBackwardsSearch range:findRange];
        }
    }
    if( result.location != NSNotFound ){
        [view setSelectedRange:NSMakeRange(result.location, 0)];
    }
    else{
        [view setSelectedRange:original];
    }
    return nil;
}


@end
