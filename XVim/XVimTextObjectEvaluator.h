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
					from:(NSUInteger)location
					  inMode:(XVIM_MODE)mode
					withParent:(XVimEvaluator*)eval
					  repeat:(NSUInteger)repeat 
				   inclusive:(BOOL)inclusive;
@end
