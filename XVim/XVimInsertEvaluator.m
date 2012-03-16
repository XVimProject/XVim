//
//  XVimInsertEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimInsertEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "Xvim.h"

@implementation XVimInsertEvaluator
- (id)init
{
    return [self initWithRepeat:1];
}

- (id)initWithRepeat:(NSUInteger)repeat{
    return [self initOneCharMode:FALSE withRepeat:repeat];
}

- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
        _oneCharMode = oneCharMode;
        _insertedEvents = [[NSMutableArray alloc] init];
        _insertedEventsAbort = NO;
    }
    return self;
}

- (void)dealloc{
    [_insertedEvents release];
    [super dealloc];
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if( [keyStr isEqualToString:@"ESC"] || [keyStr isEqualToString:@"C_LSQUAREBRACKET"] || [keyStr isEqualToString:@"C_c"]){
        if( !_insertedEventsAbort ){
            for( int i = 0 ; i < _repeat-1; i++ ){
                for( NSEvent* e in _insertedEvents ){
                    [[xvim sourceView] XVimKeyDown:e];
                }
            }
        }
        xvim.mode = MODE_NORMAL;
        [[xvim sourceView] adjustCursorPosition];
        return nil;
    }    
    
    unichar c = [[event characters] characterAtIndex:0];
    if( !_insertedEventsAbort && 63232 <= c && c <= 63235){ // arrow keys. Ignore numericArg when "ESC" is pressed
        _insertedEventsAbort = YES;
    }
    else{
        [_insertedEvents addObject:event];
    }
    
    if (_oneCharMode == TRUE) {
        NSRange save = [[xvim sourceView] selectedRange];
        [[xvim sourceView] XVimKeyDown:event];
        xvim.mode = MODE_NORMAL;
        [[xvim sourceView] setSelectedRange:save];
        return nil;
    } else {
        [[xvim sourceView] XVimKeyDown:event];
        return self;
    }
}

- (XVimRegisterOperation)shouldRecordEvent:(NSEvent*) event inRegister:(XVimRegister*)xregister{
    if (xregister.isRepeat)
    {
        return REGISTER_APPEND;
    }
    
    return [super shouldRecordEvent:event inRegister:xregister];
}

@end
