//
//  XVimSourceCodeEditor.m
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDEKit.h"
#import "DVTFoundation.h"
#import "XVimWindow.h"
#import "Logger.h"
#import "XVimStatusLine.h"
#import "XVim.h"
#import "NSObject+XVimAdditions.h"
#import "NSobject+ExtraData.h"
#import <objc/runtime.h>
#import "IDEPlaygroundEditor+XVim.h"

@implementation IDEPlaygroundEditor(XVim)

+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(didSetupEditor) with:@selector(xvim_didSetupEditor2)];
}

- (void)xvim_didSetupEditor2{
    [self xvim_didSetupEditor2]; // This is original didSetupEditor of IDEPlaygroundEditor class
    [super didSetupEditor]; // This is super class (IDESourceCodeEditor) didSetupEditor, which is hooked by XVim, resulting in calling xvim_didSetupEditor.
}
@end