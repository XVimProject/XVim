//
//  XVimTextObjectEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimMotion.h"

@class XVimOperatorAction;

@interface XVimTextObjectEvaluator : XVimEvaluator
- (id)initWithWindow:(XVimWindow *)window inner:(BOOL)inner;
- (XVimMotion *)motion;
@end
