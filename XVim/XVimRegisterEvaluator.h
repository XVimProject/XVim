//
//  XVimRegisterEvaluator.h
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimArgumentEvaluator.h"

typedef XVimEvaluator* (^OnSelectRegister) (NSString*, XVimEvaluatorContext*);

@interface XVimRegisterEvaluator : XVimArgumentEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimEvaluator*)parent 
		   completion:(OnSelectRegister)onComplete;

@end
