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
@property (nonatomic) BOOL movementKeyPressed;
@property (nonatomic, readonly, strong) NSArray *cancelKeys;
@property (nonatomic, readonly, strong) NSArray *movementKeys;
@end

@implementation XVimInsertEvaluator

@synthesize startRange = _startRange;
@synthesize cancelKeys = _cancelKeys;
@synthesize movementKeys = _movementKeys;
@synthesize movementKeyPressed = _movementKeyPressed;

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
        _movementKeyPressed = NO;
        _insertedEventsAbort = NO;
        _cancelKeys = [NSArray arrayWithObjects:@"ESC", @"C_LSQUAREBRACKET", @"C_c", nil];
        _movementKeys = [NSArray arrayWithObjects:@"Up", @"Down", @"Left", @"Right", nil];
    }
    return self;
}

- (NSString*)getInsertedText{
    NSRange endRange = [self.xvim selectedRange];
    NSRange textRange;
    if (endRange.location > self.startRange.location){
        textRange = NSMakeRange(self.startRange.location, endRange.location - self.startRange.location);
    }else{
        textRange = NSMakeRange(endRange.location, self.startRange.location - endRange.location);
    }
    
    TRACE_LOG(@"textRange %d %d", textRange.location, textRange.length);
    NSString *text = [[self.xvim string] substringWithRange:textRange];
    TRACE_LOG(@"text %@", text);
    return text;

}

- (void)recordTextIntoRegister:(XVimRegister*)xregister{
   NSString *text = [self getInsertedText];
    if (text.length > 0){
        [xregister appendText:text];
    }
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if( [self.cancelKeys containsObject:keyStr] ){
        if( !_insertedEventsAbort ){
            NSString *text = [self getInsertedText];
            for( int i = 0 ; i < _repeat-1; i++ ){
                [[xvim sourceView] insertText:text];
            }
        }
        
        // Store off any needed text
        [self recordTextIntoRegister:xvim.recordingRegister];
        [self recordTextIntoRegister:[xvim findRegister:@"repeat"]];
        
        xvim.mode = MODE_NORMAL;
        return nil;
    }else if ([self.movementKeys containsObject:keyStr]){
        _insertedEventsAbort = YES;
        if (self.movementKeyPressed == NO){
            self.movementKeyPressed = YES;
            
            // Store off any needed text
            [self recordTextIntoRegister:xvim.recordingRegister];
        }

        // Store off the new start range
        self.startRange = [self.xvim selectedRange];
    }else if(self.movementKeyPressed){
        // Flag movement key as not pressed until the next movement key is pressed
        self.movementKeyPressed = NO;

        // Store off the new start range
        self.startRange = [self.xvim selectedRange];
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
    if ([self.cancelKeys containsObject:keyStr]){
        return REGISTER_APPEND;
    }else if (xregister.isReadOnly == NO && [self.movementKeys containsObject:keyStr]){
        return REGISTER_APPEND;
    }
    
    return REGISTER_IGNORE;
}

@end
