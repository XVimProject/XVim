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
@synthesize forward = _forward;
@synthesize previous = _previous;

- (XVimEvaluator*)eval:(NSEvent *)event ofXVim:(XVim *)xvim{
    NSString *searchChar = [[event characters] substringWithRange:NSMakeRange(0, 1)];
    [xvim setSearchCharacter:searchChar backward:!self.forward previous:self.previous];

    NSTextView *view = [xvim superview];
    NSUInteger location = [view selectedRange].location;
    for (NSUInteger i = 0;;){
        location = [xvim searchCharacterNext:location];
        if (location == NSNotFound || ++i >= self.repeat){
            break;
        }

        if (self.previous){
            if (self.forward){
                location += 1;
            }else{
                location -=1;
            }
        }
    }

    if (location == NSNotFound) {
        [xvim ringBell];
    }else{
        [view setSelectedRange:NSMakeRange(location, 0)];
    }

    return nil;
}
    
@end
