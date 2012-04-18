//
//  XVimLocalMarkEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/4/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimLocalMarkEvaluator.h"
#import "XVimKeymapProvider.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "NSTextView+VimMotion.h"

@implementation XVimLocalMarkEvaluator

- (id)init
{
    return [self initWithMarkOperator:MARKOPERATOR_SET];
}

- (id)initWithMarkOperator:(XVimMarkOperator)markOperator {
    self = [super init];
    if (self) {
        _markOperator = markOperator;
    }
    return self;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider
{
	return [keymapProvider keymapForMode:MODE_NONE];
}

- (XVimEvaluator*)eval:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    NSString* keyStr = [keyStroke toSelectorString];
	if ([keyStr length] != 1) {
        return nil;
    }
    unichar c = [keyStr characterAtIndex:0];
    if (! (((c>='a' && c<='z')) || ((c>='A' && c<='Z'))) ) {
        return nil;
    }
    // we have a legal mark letter/name 
    if (_markOperator == MARKOPERATOR_SET) {
        NSRange r = [[window sourceView] selectedRange];
        NSValue *v =[NSValue valueWithRange:r];
        [[window getLocalMarks] setValue:v forKey:keyStr];
    }
    else if (_markOperator == MARKOPERATOR_MOVETO || _markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
        NSValue* v = [[window getLocalMarks] valueForKey:keyStr];
        NSRange r = [v rangeValue];
        if (v == nil) {
            return nil;
        }
        DVTSourceTextView* view = [window sourceView];
        NSString* s = [[view textStorage] string];
        if (r.location > [s length]) {
            // mark is past end of file do nothing
            return nil;
        }
        
        // TODO:
        // Marks are exclusive motion
        // They have to call motionFixedFrom with MOTION_TYPE:CHARACTERWISE_EXCLUSIVE
        [view setSelectedRange:r];
        if (_markOperator == MARKOPERATOR_MOVETOSTARTOFLINE) {
            [view moveToBeginningOfLine:nil];
            r = [view selectedRange];
            for (NSUInteger idx = r.location; idx < s.length; idx++) {// moveto 1st non whitespace
                if (![[NSCharacterSet whitespaceCharacterSet] characterIsMember:[s characterAtIndex:idx]]) break;
                [view moveRight:self];
            }
        }
        
        [view scrollTo:[view selectedRange].location];
    }
    else {
    }
    
    return nil;
}
@end
