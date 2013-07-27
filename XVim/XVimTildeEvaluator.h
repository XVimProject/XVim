//
//  XVimTildeEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 6/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOperatorEvaluator.h"

@interface XVimTildeEvaluator : XVimOperatorEvaluator
- (XVimEvaluator*)fixWithNoMotion:(NSUInteger)count;
@end
