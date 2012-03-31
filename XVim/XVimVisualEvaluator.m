//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimVisualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"
#import "Logger.h"
#import "XVimEqualEvaluator.h"
#import "XVimDeleteEvaluator.h"
#import "XVimYankEvaluator.h"
#import "DVTSourceTextView.h"

@implementation XVimVisualEvaluator 

- (NSUInteger)insertionPoint{
    return _insertion;
}

- (id)initWithMode:(VISUAL_MODE)mode{ 
    self = [super init];
    if (self) {
        _mode = mode;
    }
    return self;
}

- (XVimEvaluator*)defaultNextEvaluator{
    // This is quick hack. When unsupported keys are pressed in Visual mode we have to set selection
    // because in "eval:ofXVim:" method we cancel the selection temporarily to handle motion.
    // Because methods handles supporeted keys call motionFixedFrom:To: method to update the selection
    // we do not need to call updateSelection.
    // Since this method is called when unsupported keys are pressed I use here to call updateSelection but its not clear why we call this here.
    // We should make another process for this.
    [self updateSelection]; 
    return self;
}

- (XVIM_MODE)becameHandler:(XVim *)xvim{
    self.xvim = xvim;
    DVTSourceTextView* view = (DVTSourceTextView*)[xvim sourceView];
    NSRange cur = [view selectedRange];
    _begin = cur.location;
    _insertion = cur.location + cur.length;
    if( _mode == MODE_CHARACTER ){
        [view setSelectedRangeWithBoundsCheck:cur.location To:cur.location];
    }
    if( _mode == MODE_LINE ){
        NSUInteger head = [view headOfLine:cur.location];
        NSUInteger end = [view endOfLine:cur.location];
        if( NSNotFound != head && NSNotFound != end ){
            [view setSelectedRangeWithBoundsCheck:head To:end];
        }else{
            [view setSelectedRangeWithBoundsCheck:cur.location To:cur.location];
        }
    }
    
    return MODE_VISUAL;
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    DVTSourceTextView* v = [xvim sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    [v adjustCursorPosition];
    XVimEvaluator *nextEvaluator = [super eval:event ofXVim:xvim];
    if (nextEvaluator == self){
        [self updateSelection];   
    }
    return nextEvaluator;
}


- (void)updateSelection{
    NSTextView* view = [self textView];
    if( _mode == MODE_CHARACTER ){
        _selection_begin = _begin;
        _selection_end = _insertion;
    }else if( _mode == MODE_LINE ){
        NSUInteger begin = _begin;
        NSUInteger end = _insertion;
        if( _begin > _insertion ){
            begin = _insertion;
            end = _begin;
        }
        _selection_begin = [view headOfLine:begin];
        if( NSNotFound == _selection_begin ){
            _selection_begin = begin;
        }
        _selection_end = [view tailOfLine:end];
    }else if( _mode == MODE_BLOCK){
        // later
    }
    [view setSelectedRangeWithBoundsCheck:_selection_begin To:_selection_end];
    [view scrollToCursor];
}

- (XVimEvaluator*)C_b:(id)arg{
    _insertion = [[self textView] pageBackward:[[self textView] selectedRange].location count:[self numericArg]];
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)C_d:(id)arg{
    _insertion = [[self textView] halfPageForward:[[self textView] selectedRange].location count:[self numericArg]];
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)C_f:(id)arg{
    _insertion = [[self textView] pageForward:[[self textView] selectedRange].location count:[self numericArg]];
    [self updateSelection];
    return self;
}


- (XVimEvaluator*)c:(id)arg{
    [self updateSelection];
    XVimDeleteEvaluator *evaluator =
    [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:YES];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)d:(id)arg{
    [self updateSelection];
    XVimDeleteEvaluator *evaluator =
    [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:NO];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE];
}


- (XVimEvaluator*)D:(id)arg{
    [self updateSelection];
    XVimDeleteEvaluator *evaluator = [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:NO];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:LINEWISE];
    
}

- (XVimEvaluator*)C_u:(id)arg{
    _insertion = [[self textView] halfPageBackward:[[self textView] selectedRange].location count:[self numericArg]];
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)v:(id)arg{
    if( _mode == MODE_CHARACTER ){
        // go to normal mode
        return  [self ESC:arg];
    }
    _mode = MODE_CHARACTER;
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)V:(id)arg{
    if( MODE_LINE == _mode ){
        // go to normal mode
        return  [self ESC:arg];
    }
    _mode = MODE_LINE;
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)x:(id)arg{
    return [self d:arg];
}

- (XVimEvaluator*)X:(id)arg{
    return [self D:arg];
}

- (XVimEvaluator*)y:(id)arg{
    [self updateSelection];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithRepeat:[self numericArg]];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)EQUAL:(id)arg{
    [self updateSelection];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithRepeat:[self numericArg]];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_selection_begin To:_selection_end Type:CHARACTERWISE_INCLUSIVE];
}


- (XVimEvaluator*)ESC:(id)arg{
    [[self textView] setSelectedRange:NSMakeRange(_insertion, 0)];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    [self updateSelection];
    DVTSourceTextView* view = (DVTSourceTextView*)[self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}


- (XVimEvaluator*)LESSTHAN:(id)arg{
    [self updateSelection];
    DVTSourceTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
}
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    //TODO: Handle type
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelection];
    return self;
}
@end

