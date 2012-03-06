//
//  XVimEqualEvaluator.m
//  XVim
//
//  Created by Nader Akoury on 3/5/2012
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimEqualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVimMotionEvaluator.h"
#import <CoreServices/CoreServices.h>

@implementation XVimEqualEvaluator
- (id)init{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
   self = [super init];
   if (self) {
       _repeat = repeat;
   }
    return self;
}

+ (void)indent:(XVimEvaluator*)evaluator{
    // TODO: Find the proper function call to do an indent instead of faking an NSEvent
    NSTextView *view = [evaluator textView];
    NSTimeInterval currentEventTime = 0.001 * AbsoluteToDuration(UpTime());
    NSEvent *event = [NSEvent keyEventWithType:NSKeyDown location:NSMakePoint(0, 0) modifierFlags:NSControlKeyMask timestamp:currentEventTime windowNumber:[[view window] windowNumber] context:[NSGraphicsContext currentContext] characters:@"i" charactersIgnoringModifiers:@"i" isARepeat:NO keyCode:'i'];
    [[NSApplication sharedApplication] postEvent:event atStart:YES];
}

- (XVimEvaluator*)EQUAL:(id)arg{
    NSTextView *view = [self textView];
    NSRange begin = [view selectedRange];
    [view moveToBeginningOfLine:self];
    NSRange start = [view selectedRange];
    for (int i = 1; i < _repeat; i++) {
        [view moveDown:self];
    }
    
    [view moveToEndOfLine:self];
    [view moveForward:self]; // include eol
    
    NSRange end = [view selectedRange];
    [view setSelectedRange:NSMakeRange(begin.location, end.location - begin.location)];
    
    [XVimEqualEvaluator indent:self];
    
    // set cursor back to original position
    [view setSelectedRange:begin];
    
    NSUInteger max = [[view string] length] - 1;
    return [self _motionFixedFrom:start.location To:end.location>max?max:end.location Type:LINEWISE];
}

-(XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    NSTextView* view = [self textView];
    if( from > to ){
        NSUInteger tmp = from;
        from = to;
        to = tmp;
    }
    if( to != 0 && type == CHARACTERWISE_EXCLUSIVE){
        to--;
    }else if( type == LINEWISE ){
        [view setSelectedRange:NSMakeRange(to,0)];
        to = [view nextNewline];
        if( NSNotFound == to ){
            to = [view string].length-1;
        }
        
        NSRange r = [view selectedRange];
        [view setSelectedRange:NSMakeRange(from,0)];
        from = [view prevNewline];
        [view setSelectedRange:r];
        if( NSNotFound == from ){
            from = 0;
        }else{
            from++;
        }
    }
    
    // TODO: Preserve current cursor position. Currently cannot do this
    // because indent fakes a key press which happens after this function returns.
    [view setSelectedRangeWithBoundsCheck:from To:to];
    [XVimEqualEvaluator indent:self];
    return nil;
}

@end