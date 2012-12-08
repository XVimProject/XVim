//
//  XVimMarkMotionEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimMotionArgumentEvaluator.h"

typedef enum {
	MARKOPERATOR_MOVETO,
	MARKOPERATOR_MOVETOSTARTOFLINE
} XVimMarkOperator;

@interface XVimMarkMotionEvaluator : XVimMotionArgumentEvaluator

- (id)initWithContext:(XVimEvaluatorContext*)context
           withWindow:(XVimWindow *)window
			   withParent:(XVimMotionEvaluator*)parent
		 markOperator:(XVimMarkOperator)markOperator;

+ (NSUInteger)markLocationForMark:(NSString*)mark inWindow:(XVimWindow*)window;

@end
