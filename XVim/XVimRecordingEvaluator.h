//
//  XVimRecordingEvaluator.h
//  XVim
//
//  Created by Suzuki Shuichiro on 7/13/13.
//
//

#import "XVimEvaluator.h"

@interface XVimRecordingEvaluator : XVimEvaluator
- (id)initWithWindow:(XVimWindow *)window withRegister:(NSString*)reg;
    
@end
