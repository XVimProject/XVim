//
//  XVimInsertEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/1/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@interface XVimInsertEvaluator : XVimEvaluator

- (id)initWithWindow:(XVimWindow *)window oneCharMode:(BOOL)oneCharMode;

@end
