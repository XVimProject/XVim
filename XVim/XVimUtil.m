//
//  XVimUtil.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import "XVimUtil.h"
#import "DVTFoundation.h"
#import "DVTKit.H"
#import "IDEKit.h"

IDEWorkspaceWindowController* XVimLastActiveWindowController(){
    return [[IDEWorkspaceWindow lastActiveWorkspaceWindow] windowController];
}

IDEEditorArea* XVimLastActiveEditorArea(){
    return [XVimLastActiveWindowController() editorArea];
}
    
DVTSourceTextView* XVimLastActiveSourceView(){
    return [[[[XVimLastActiveEditorArea() lastActiveEditorContext] editor] mainScrollView] documentView];
}

@implementation XVimUtil

@end
