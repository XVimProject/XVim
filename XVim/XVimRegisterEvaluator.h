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
@property(strong) NSString* reg;
@end

@interface XVimRecordingRegisterEvaluator : XVimRegisterEvaluator
@end
