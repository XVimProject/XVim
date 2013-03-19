//
//  XVimChildEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class XVimKeyStroke;
#import "XVimEvaluator.h"

@interface XVimArgumentEvaluator : XVimEvaluator {
}
@property(strong) XVimKeyStroke* keyStroke;
@end
