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
#import "XVimKeyStroke.h"
#import "DVTSourceTextView.h"
#import "DVTCompletionController.h"

@interface XVimInsertEvaluator()
@property (nonatomic) NSRange startRange;
@property (nonatomic) BOOL movementKeyPressed;
@property (nonatomic, strong) NSString *lastInsertedText;
@property (nonatomic, readonly, strong) NSArray *cancelKeys;
@property (nonatomic, readonly, strong) NSArray *movementKeys;
@end

@implementation XVimInsertEvaluator

@synthesize startRange = _startRange;
@synthesize cancelKeys = _cancelKeys;
@synthesize movementKeys = _movementKeys;
@synthesize lastInsertedText = _lastInsertedText;
@synthesize movementKeyPressed = _movementKeyPressed;

- (id)initWithRepeat:(NSUInteger)repeat{
    return [self initOneCharMode:FALSE withRepeat:repeat];
}

- (id)initOneCharMode:(BOOL)oneCharMode withRepeat:(NSUInteger)repeat{
    self = [super init];
    if (self) {
        _repeat = repeat;
        _lastInsertedText = @"";
        _oneCharMode = oneCharMode;
        _movementKeyPressed = NO;
        _insertedEventsAbort = NO;
        _cancelKeys = [NSArray arrayWithObjects:
                       [NSValue valueWithPointer:@selector(ESC:)],
                       [NSValue valueWithPointer:@selector(C_LSQUAREBRACKET:)],
                       [NSValue valueWithPointer:@selector(C_c:)],
                       nil];
        _movementKeys = [NSArray arrayWithObjects:
                         [NSValue valueWithPointer:@selector(Up:)],
                         [NSValue valueWithPointer:@selector(Down:)],
                         [NSValue valueWithPointer:@selector(Left:)],
                         [NSValue valueWithPointer:@selector(Right:)],
                         nil];
    }
    return self;
}

- (XVIM_MODE)becameHandler:(XVim *)xvim{
    self.startRange = [xvim selectedRange];
    return MODE_INSERT;
}

- (XVimKeymap*)selectKeymap:(XVimKeymap**)keymaps
{
    return keymaps[MODE_INSERT];
}

- (NSString*)getInsertedTextOfXVim:(XVim*)xvim {
    NSRange endRange = [xvim selectedRange];
    NSRange textRange;
    if (endRange.location > self.startRange.location){
        textRange = NSMakeRange(self.startRange.location, endRange.location - self.startRange.location);
    }else{
        textRange = NSMakeRange(endRange.location, self.startRange.location - endRange.location);
    }
    
    NSString *text = [[xvim string] substringWithRange:textRange];
    return text;
    
}

- (void)recordTextIntoRegister:(XVimRegister*)xregister XVim:(XVim*)xvim {
    NSString *text = [self getInsertedTextOfXVim:xvim];
    if (text.length > 0){
        [xregister appendText:text];
    }
}

- (void)onMovementKeyPressed:(XVim*)xvim {
    _insertedEventsAbort = YES;
    if (!self.movementKeyPressed){
        self.movementKeyPressed = YES;
        
        // Store off any needed text
        self.lastInsertedText = [self getInsertedTextOfXVim:xvim];
        [self recordTextIntoRegister:xvim.recordingRegister XVim:xvim];
    }
    
    // Store off the new start range
    self.startRange = [xvim selectedRange];
}

- (void)onFinishInsert:(XVim*)xvim {
    if( !_insertedEventsAbort ){
        NSString *text = [self getInsertedTextOfXVim:xvim];
        for( int i = 0 ; i < _repeat-1; i++ ){
            [[xvim sourceView] insertText:text];
        }
    }
    
    // Store off any needed text
    if (!self.movementKeyPressed){
        [self recordTextIntoRegister:xvim.recordingRegister XVim:xvim];
        [self recordTextIntoRegister:[xvim findRegister:@"repeat"] XVim:xvim];
    }else if(self.lastInsertedText.length > 0){
        [[xvim findRegister:@"repeat"] appendText:self.lastInsertedText];
    }
    [[[xvim sourceView] completionController] hideCompletions];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke XVim:(XVim*)xvim{
    XVimEvaluator *nextEvaluator = self;
    SEL keySelector = [keyStroke selectorForInstance:self];
    if (keySelector){
        nextEvaluator = [self performSelector:keySelector withObject:xvim];
    }else if(self.movementKeyPressed){
        // Flag movement key as not pressed until the next movement key is pressed
        self.movementKeyPressed = NO;
        
        // Store off the new start range
        self.startRange = [xvim selectedRange];
    }
    
    if (nextEvaluator != nil){
        NSEvent *event = [keyStroke toEvent];
        if (_oneCharMode == TRUE) {
            NSRange save = [[xvim sourceView] selectedRange];
            for (NSUInteger i = 0; i < _repeat; ++i) {
                [[xvim sourceView] deleteForward:self];
                [[xvim sourceView] keyDown_:event];
                
                save.location += 1;
                [[xvim sourceView] setSelectedRange:save];
            }
            save.location -= 1;
            [[xvim sourceView] setSelectedRange:save];
            nextEvaluator = nil;
        } else {
            [[xvim sourceView] keyDown_:event];
        }
    }
    
    if( self != nextEvaluator ){
        [[xvim sourceView] adjustCursorPosition];
    }
    return nextEvaluator;
}

- (XVimEvaluator*)ESC:(XVim*)xvim{
    [self onFinishInsert:xvim];
    return nil;
}

- (XVimEvaluator*)C_LSQUAREBRACKET:(XVim*)xvim{
    [self onFinishInsert:xvim];
    return nil;
}

- (XVimEvaluator*)C_c:(XVim*)xvim{
    [self onFinishInsert:xvim];
    return nil;
}

- (XVimEvaluator*)Up:(XVim*)xvim{
    [self onMovementKeyPressed:xvim];
    return self;
}

- (XVimEvaluator*)Down:(XVim*)xvim{
    [self onMovementKeyPressed:xvim];
    return self;
}

- (XVimEvaluator*)Left:(XVim*)xvim{
    [self onMovementKeyPressed:xvim];
    return self;
}

- (XVimEvaluator*)Right:(XVim*)xvim{
    [self onMovementKeyPressed:xvim];
    return self;
}

- (XVimRegisterOperation)shouldRecordEvent:(XVimKeyStroke*)keyStroke inRegister:(XVimRegister*)xregister{
    // Do not record key strokes for insert. Instead we will directly append the inserted text into the register.
    NSValue *keySelector = [NSValue valueWithPointer:[keyStroke selectorForInstance:self]];
    if ([self.cancelKeys containsObject:keySelector]){
        return REGISTER_APPEND;
    }else if (xregister.isReadOnly == NO && ([self.movementKeys containsObject:keySelector] || _oneCharMode)){
        return REGISTER_APPEND;
    }else if (xregister.isRepeat && _oneCharMode){
        return REGISTER_APPEND;
    }
    
    return REGISTER_IGNORE;
}

@end
