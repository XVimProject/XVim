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
@property BOOL inner;
@property MOTION textobject;
@property BOOL bigword;

- (id)initWithContext:(XVimEvaluatorContext*)context
           withWindow:(XVimWindow *)window
           withParent:(XVimEvaluator*)parent
            inner:(BOOL)inner;
@end
