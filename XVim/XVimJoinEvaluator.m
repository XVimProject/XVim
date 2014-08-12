//
//  XVimJoinEvaluator.m
//  XVim
//
//  Created by Suzuki Shuichiro on 9/6/13.
//
//

#import "XVimJoinEvaluator.h"
#import "NSTextView+VimOperation.h"
#import "XVimWindow.h"

@implementation XVimJoinEvaluator {
    BOOL _addSpace;
}

- (instancetype)initWithWindow:(XVimWindow *)window addSpace:(BOOL)addSpace
{
    if ((self = [self initWithWindow:window])) {
        _addSpace = addSpace;
    }
    return self;
}

- (XVimEvaluator*)motionFixed:(XVimMotion*)motion{
    if( motion.count > 1 ){
        // J and 2J is the same
        motion.count--;
    }
    [self.window.sourceView xvim_join:motion.count addSpace:_addSpace];
    return nil;
}

@end
