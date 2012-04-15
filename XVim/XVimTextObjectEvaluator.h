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
- (id)initWithOperatorAction:(XVimOperatorAction*)operatorAction 
					withParent:(XVimEvaluator*)parent
					  numericArg:(NSUInteger)numericArg
				   inclusive:(BOOL)inclusive;
@end
