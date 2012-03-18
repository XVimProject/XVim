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
#import "Logger.h"

@interface XVimInsertEvaluator()
    @property (nonatomic) NSRange startRange;
@end

@implementation XVimInsertEvaluator

@synthesize startRange = _startRange;

- (id)initWithRepeat:(NSUInteger)repeat ofXVim:(XVim *)xvim{
    return [self initOneCharMode:FALSE withRepeat:repeat ofXVim:xvim];
}

- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat ofXVim:(XVim *)xvim{
    self = [super initWithXVim:xvim];
    if (self) {
        _startRange = [xvim selectedRange];
        xvim.mode = MODE_INSERT;
        
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

- (void)recordText:(NSString*)text intoRegister:(XVimRegister*)xregister{
    [xregister appendText:text];
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
        
        if ([xvim isPlayingRegisterBack] == NO){
            NSRange endRange = [xvim selectedRange];
            // Temorarily this is enalbed only when start location is less than end location.
            if( endRange.location > self.startRange.location ){
                NSRange textRange = NSMakeRange(self.startRange.location, endRange.location - self.startRange.location);
                TRACE_LOG(@"textRange %d %d", textRange.location, textRange.length);
                
                NSString *text = [xvim string];
                NSString *insertedText = [text substringWithRange:textRange];
                [self recordText:insertedText intoRegister:[xvim findRegister:@"repeat"]];
                [self recordText:insertedText intoRegister:xvim.recordingRegister];
            }        
        }
        
        
        xvim.mode = MODE_NORMAL;
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
    // Do not record key strokes for insert. Instead we will directly append the inserted text into the register.
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if([keyStr isEqualToString:@"ESC"] || [keyStr isEqualToString:@"C_LSQUAREBRACKET"] || [keyStr isEqualToString:@"C_c"]){
        return REGISTER_APPEND;
    }
    
    return REGISTER_IGNORE;
}

@end
