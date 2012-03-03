//
//  XVimLocalMarkEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/4/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimLocalMarkEvaluator.h"

@implementation XVimLocalMarkEvaluator

- (id)init
{
    return [self initWithMarkOperator:MARKOPERATOR_SET xvimTarget:nil];
}

- (id)initWithMarkOperator:(XVimMarkOperator)markOperator xvimTarget:(XVim *)xvimTarget{
    self = [super init];
    if (self) {
        _markOperator = markOperator;
        _xvimTarget = xvimTarget;
    }
    return self;
}

- (XVimEvaluator*)eval:(NSEvent*)event ofXVim:(XVim*)xvim{
    NSString* keyStr = [XVimEvaluator keyStringFromKeyEvent:event];
    if ([keyStr length] != 1) {
        return nil;
    }
    unichar c = [keyStr characterAtIndex:0];
    if (! (((c>='a' && c<='z')) || ((c>='A' && c<='Z'))) ) {
        return nil;
    }
    // we have a legal mark letter/name 
    if (_markOperator == MARKOPERATOR_SET) {
        NSRange r = [[_xvimTarget sourceView] selectedRange];
        NSValue *v =[NSValue valueWithRange:r];
        [[_xvimTarget getLocalMarks] setValue:v forKey:keyStr];
    }
    else if (_markOperator == MARKOPERATOR_MOVETO || _markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
        NSValue* v = [[_xvimTarget getLocalMarks] valueForKey:keyStr];
        NSRange r = [v rangeValue];
        if (v == nil) {
            return nil;
        }
        NSTextView* view = [_xvimTarget sourceView];
        NSString* s = [[view textStorage] string];
        if (r.location > [s length]) {
            // mark is past end of file do nothing
            return nil;
        }
        
        [view setSelectedRange:r];
        if (_markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
            [view moveToBeginningOfLine:nil];
            r = [view selectedRange];
            for (NSUInteger idx = r.location; idx < s.length; idx++) {// moveto 1st non whitespace
                if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]]) break;
                [view moveRight:self];
            }
        }
    }
    else {
    }
    
    return nil;
}
@end
