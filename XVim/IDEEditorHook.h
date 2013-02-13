//
//  IDEEditor.h
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IDEKit.h"

@interface IDEEditorHook : NSViewController
+(void) hook;
@end

@interface IDEEditor(Hook)
- (void)didSetupEditor_;
- (void)primitiveInvalidate_;
@end
