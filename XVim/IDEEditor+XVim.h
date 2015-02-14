//
//  IDEEditor.h
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IDEKit.h"


@interface IDEEditor(XVim)
+ (void)xvim_initialize;
- (void)xvim_didSetupEditor;
- (void)xvim_primitiveInvalidate;
@end
