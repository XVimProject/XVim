//
//  XVimVisualEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

// Currently the navigation in VISUAL MODE is not corresponds to that of NORMAL MODE.
// We may be able reuse NormalEvaluator as Super class of VisualEvaluator
// (I have tried once but the problem was when we want to expand the selection range. I did not think well 
// about the problem so it might not be a big problem.)
// 

#import "XVimVisualEvaluator.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"
#import "Logger.h"

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

- (XVimEvaluator*)d:(id)arg{
    [self updateSelection];
    NSTextView* view = [self textView];
    [view cut:self];
    return nil;
}

- (XVimEvaluator*)y:(id)arg{
    [self updateSelection];
    NSTextView* view = [self textView];
    NSRange r = [view selectedRange];
    [view copy:self];
    r.length = 0;
    [view setSelectedRange:r];
    return nil;
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

- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to{
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelection];
    return self;
}
@end

