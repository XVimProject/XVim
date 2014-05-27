//
//  XVimJoinEvaluator.h
//  XVim
//
//  Created by Suzuki Shuichiro on 9/6/13.
//
//

#import "XVimOperatorEvaluator.h"

@interface XVimJoinEvaluator : XVimOperatorEvaluator
- (instancetype)initWithWindow:(XVimWindow *)window addSpace:(BOOL)addsSpace;
@end
