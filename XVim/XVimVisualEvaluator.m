//
//  XVimVisualEvaluator.m
//  XVim
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

@implementation XVimVisualEvaluator 

- (id)initWithMode:(VISUAL_MODE)mode initialSelection:(NSUInteger)begin :(NSUInteger)end{
    self = [super init];
    if (self) {
        _begin = begin; 
        _insertion = end;
        _mode = mode;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    METHOD_TRACE_LOG();
    NSTextView* v = [xvim sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    return [super eval:event ofXVim:xvim];
}

- (XVimEvaluator*)defaultNextEvaluator{
    [self updateSelection];
    return self;
}

- (XVimEvaluator*)C_b:(id)arg{
    return [self commonMotion:@selector(pageBackward:) Type:LINEWISE];
}

- (XVimEvaluator*)C_d:(id)arg{
    return [self commonMotion:@selector(halfPageForward:) Type:LINEWISE];
}

- (XVimEvaluator*)C_f:(id)arg{
    return [self commonMotion:@selector(pageForward:) Type:LINEWISE];
}

- (XVimEvaluator*)C_u:(id)arg{
    return [self commonMotion:@selector(halfPageBackward:) Type:LINEWISE];
}

- (void)updateSelection{
    NSTextView* view = [self textView];
    if( _mode == MODE_CHARACTER ){
        NSRange newRange = NSMakeRange(_begin<_insertion?_begin:_insertion, _begin<_insertion?_insertion-_begin:_begin-_insertion);
        [view setSelectedRange:newRange];
    }else if( _mode == MODE_LINE ){
        NSUInteger begin,end;
        if( _begin < _insertion ){
            [view setSelectedRange:NSMakeRange(_begin,0)];
            [view moveToBeginningOfLine:self];
            begin = [view selectedRange].location;
            [view setSelectedRange:NSMakeRange(_insertion,0)];
            [view moveToEndOfLine:self];
            end = [view selectedRange].location;
        }else{
            [view setSelectedRange:NSMakeRange(_insertion,0)];
            [view moveToBeginningOfLine:self];
            begin = [view selectedRange].location;
            [view setSelectedRange:NSMakeRange(_begin,0)];
            [view moveToEndOfLine:self];
            end = [view selectedRange].location;
        }
        [view setSelectedRange:NSMakeRange(begin,end-begin)];
    }else if( _mode == MODE_BLOCK){
        // later
    }
}

- (XVimEvaluator*)c:(id)arg{
    [self updateSelection];
    XVimDeleteEvaluator *evaluator =
    [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:YES];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_begin To:_insertion Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)d:(id)arg{
    [self updateSelection];
    XVimDeleteEvaluator *evaluator =
    [[XVimDeleteEvaluator alloc] initWithRepeat:[self numericArg] insertModeAtCompletion:NO];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_begin To:_insertion Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)y:(id)arg{
    [self updateSelection];
    XVimYankEvaluator *evaluator = [[XVimYankEvaluator alloc] initWithRepeat:[self numericArg]];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_begin To:_insertion Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)EQUAL:(id)arg{
    [self updateSelection];
    XVimEqualEvaluator *evaluator = [[XVimEqualEvaluator alloc] initWithRepeat:[self numericArg]];
    
    // Need to set this explicitly because it is not in the constructor.
    // Maybe the constructors should be refactored to include it?
    evaluator.xvim = self.xvim;
    return [evaluator motionFixedFrom:_begin To:_insertion Type:CHARACTERWISE_INCLUSIVE];
}

- (XVimEvaluator*)ESC:(id)arg{
    [self xvim].mode = MODE_NORMAL;
    [[self textView] setSelectedRange:NSMakeRange(_begin, 0)];
    return nil;
}

- (XVimEvaluator*)GREATERTHAN:(id)arg{
    [self updateSelection];
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftRight:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}

- (XVimEvaluator*)LESSTHAN:(id)arg{
    [self updateSelection];
    NSTextView* view = [self textView];
    for( int i = 0; i < [self numericArg]; i++ ){
        [view shiftLeft:self];
    }
    NSRange r = [[self textView] selectedRange];
    r.length = 0;
    [view setSelectedRange:r];
    [self resetNumericArg];
    [self xvim].mode = MODE_NORMAL;
    return nil;
}

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:type{
    //TODO: Handle type
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelection];
    return self;
}
@end

