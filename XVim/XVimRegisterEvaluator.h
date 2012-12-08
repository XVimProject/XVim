//
//  XVimRegisterEvaluator.h
//  XVim
//
//  Created by Nader Akoury on 3/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"
#import "XVimArgumentEvaluator.h"

@interface XVimRegisterEvaluator : XVimArgumentEvaluator

- (void)registerFixed:(NSString*)rname;

- (id)initWithContext:(XVimEvaluatorContext *)context withWindow:(XVimWindow*)window withParent:(XVimEvaluator*)parent;

@end

@interface XVimRecordingRegisterEvaluator : XVimRegisterEvaluator

@end

