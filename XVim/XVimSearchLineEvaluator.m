//
//  XVimSearchEvaluator.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/19/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearchLineEvaluator.h"
#import "XVim.h"
#import "Logger.h"

// Search Line 
@implementation XVimSearchLineEvaluator
@synthesize forward;

- (XVimEvaluator*)eval:(NSEvent *)event ofXVim:(XVim *)xvim{
    unichar searchChar = [[event characters] characterAtIndex:0];
    NSTextView* view = [xvim sourceView];
    NSRange original = [view selectedRange];
    NSString* source = [view string];
    NSRange result = NSMakeRange(NSNotFound, 0);
    NSUInteger num = [self repeat];
    if( forward ){
        // Get the position of the newlinebreak
        NSRange nextNewline = [source rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:0 range:NSMakeRange(original.location, source.length-original.location)];
        if( nextNewline.location == NSNotFound ){
            nextNewline.location = source.length;
        }
        // find the char forwards for "num" times
        for( NSUInteger i = original.location+1; i < nextNewline.location; i++ ){
            if( [source characterAtIndex:i] == searchChar ){
                num--;
                if( 0 == num ){
                    result.location = i;
                    break;
                }
            }
        }
    }
    else{
        // Get the position of the prev newlinebreak
        if( 0 == original.location )
            return nil;
        
        NSRange prevNewLine= [source rangeOfCharacterFromSet:[NSCharacterSet newlineCharacterSet] options:NSBackwardsSearch range:NSMakeRange(0, original.location)];
        if( prevNewLine.location == NSNotFound ){
            prevNewLine.location = 0;
        }
        // find the char backwards for "num" times
        for( NSUInteger i = original.location-1; i >= prevNewLine.location; i-- ){
            if( [source characterAtIndex:i] == searchChar ){
                num--;
                if( 0 == num ){
                    result.location = i;
                    break;
                }
            }
            if( 0 == i ){
                break; // since i is unsigned, we need this.
            }
        }
    }
    if( result.location != NSNotFound ){
        TRACE_LOG(@"%d %d", original.location, result.location );
        return [self _motionFixedFrom:original.location To:result.location Type:CHARACTERWISE_INCLUSIVE];
    }
    return nil;
}
    
@end
