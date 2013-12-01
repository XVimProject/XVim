//
//  XVimLowercaseEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOperatorEvaluator.h"

@interface XVimSwapCharsEvaluator : XVimOperatorEvaluator
- (instancetype)initWithWindow:(XVimWindow *)window mode:(int)mode;
@end
