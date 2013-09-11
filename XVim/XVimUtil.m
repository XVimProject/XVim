//
//  XVimUtil.m
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#define __XCODE5__

#import "XVimUtil.h"
#import "DVTFoundation.h"
#import "DVTKit.H"
#import "IDEKit.h"


IDEWorkspaceWindowController* XVimLastActiveWindowController(){
#ifdef __XCODE5__
    // TODO: Must update IDEKit.h for Xcodr5
    return [IDEWorkspaceWindow performSelector:@selector(lastActiveWorkspaceWindowController)];
#else
    return [[IDEWorkspaceWindow lastActiveWorkspaceWindow] windowController];
#endif
    
}

IDEWorkspaceTabController* XVimLastActiveWorkspaceTabController(){
    return [XVimLastActiveWindowController() activeWorkspaceTabController];
}

IDEEditorArea* XVimLastActiveEditorArea(){
    return [XVimLastActiveWindowController() editorArea];
}
    
DVTSourceTextView* XVimLastActiveSourceView(){
    return [[[[XVimLastActiveEditorArea() lastActiveEditorContext] editor] mainScrollView] documentView];
}

@implementation XVimUtil

@end
