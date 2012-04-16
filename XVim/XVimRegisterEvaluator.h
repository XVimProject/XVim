//
//  XVimRegisterEvaluator.h
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

typedef XVimEvaluator* (^OnSelectRegister) (NSString*, XVimEvaluatorContext*);

@interface XVimRegisterEvaluator : XVimEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
			   parent:(XVimEvaluator*)parent 
		   completion:(OnSelectRegister)onComplete;

@end
