//
//  XVimMarkMotionEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimArgumentEvaluator.h"
@class XVimMark;

@interface XVimMarkMotionEvaluator : XVimArgumentEvaluator
- (id)initWithWindow:(XVimWindow *)window;
@end
