//
//  XVimTextObjectEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@class XVimOperatorAction;

@interface XVimTextObjectEvaluator : XVimEvaluator
- (id)initWithContext:(XVimEvaluatorContext*)context
	   operatorAction:(XVimOperatorAction*)operatorAction 
					withParent:(XVimEvaluator*)parent
				   inclusive:(BOOL)inclusive;
@end
