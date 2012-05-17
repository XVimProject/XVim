//
//  DVTSourceTextView+XVim.h
//  XVim
//
//  Created by Suzuki Shuichiro on 5/18/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class XVimCommandLine;

#import "DVTKit.h"

@interface DVTSourceTextView (XVim)
- (XVimCommandLine*)commandLine;
@end
