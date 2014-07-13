//
//  XVimEditorArea.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "IDEEditorAreaHook.h"
#import "Hooker.h"
#import "DVTKit.h"
#import "IDEEditorArea+XVim.h"

@implementation IDEEditorAreaHook
/**
 * IDEEditorArea is a area including primary editor and assistant editor and debug area (The view right of the navigator)
 * This class hooks IDEEditorArea and does some works.
 * "viewDidInstall" is called when the view setup is done ( as far as I saw the behaviour ).
 * This class has private instance variable named "_editorAreaAutoLayoutView" which is the view
 * contains source code editores and border view between editors and debug area.
 * We insert command line view between editors and debug area.
 *
 * IDEEdiatorArea exists in every Xcode tabs so if you have 4 tabs in a Xcode window there are 4 command line and XVimWindow views we insert.
 **/

+(void)hook
{
    Class c = NSClassFromString(@"IDEEditorArea");
    
    [Hooker hookMethod:@selector(viewDidInstall) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(viewDidInstall) ) keepingOriginalWith:@selector(viewDidInstall_)];
    [Hooker hookMethod:@selector(primitiveInvalidate) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(primitiveInvalidate)) keepingOriginalWith:@selector(primitiveInvalidate_)];
}

- (void)viewDidInstall
{
    IDEEditorArea *base = (IDEEditorArea *)self;

    [base viewDidInstall_];
    [base setupXVim];
}

- (void)primitiveInvalidate
{
    IDEEditorArea *base = (IDEEditorArea*)self;

    [base teardownXVim];
    [base primitiveInvalidate_];
}

@end
