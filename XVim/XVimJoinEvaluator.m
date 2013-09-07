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

@implementation XVimJoinEvaluator
-(XVimEvaluator*)motionFixed:(XVimMotion*)motion{
    if( motion.count > 1 ){
        // J and 2J is the same
        motion.count--;
    }
    [self.window.sourceView xvim_join:motion.count];
    return nil;
}
@end
