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
    NSTextView* v = [xvim sourceView];
    [v setSelectedRange:NSMakeRange(_insertion, 0)]; // temporarily cancel the current selection
    return [super eval:event ofXVim:xvim];
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
            begin = [view headOfLine];
            [view setSelectedRange:NSMakeRange(_insertion,0)];
            if( _insertion != [[view string] length] && !isNewLine( [[view string] characterAtIndex:_insertion]) ){
                end = [view nextNewline];
                if( end == NSNotFound ){
                    end = [view endOfLine];
                }
            }else{
                end = _insertion;
            }
        }else{
            [view setSelectedRange:NSMakeRange(_insertion,0)];
            begin = [view headOfLine];
            [view setSelectedRange:NSMakeRange(_begin,0)];
            if( _begin != [[view string] length] && !isNewLine( [[view string] characterAtIndex:_begin]) ){
                end = [view nextNewline];
                if( end == NSNotFound ){
                    end = [view endOfLine];
                }
            }else{
                end = _begin;
            }
        }
        [view setSelectedRangeWithBoundsCheck:begin To:end];
    }else if( _mode == MODE_BLOCK){
        // later
    }
    [view scrollRangeToVisible:NSMakeRange(_insertion,0)];
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

- (XVimEvaluator*)EQUAL:(id)arg{
    [self updateSelection];
    // Not implemented yet. Will share the code in the XVimEqualEvaluator
    //[XVimEqualEvaluator indent:self];
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
- (XVimEvaluator*)motionFixedFrom:(NSUInteger)from To:(NSUInteger)to Type:(MOTION_TYPE)type{
    //TODO: Handle type
    // Expand current selected range (_begin, _insertion )
    _insertion = to;
    [self updateSelection];
    return self;
}
@end

