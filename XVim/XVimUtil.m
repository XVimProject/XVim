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
#if XVIM_XCODE_VERSION == 5
    // TODO: Must update IDEKit.h for Xcodr5
    return [IDEWorkspaceWindow performSelector:@selector(lastActiveWorkspaceWindowController)];
#elif XVIM_XCODE_VERSION == 4
    return [[IDEWorkspaceWindow lastActiveWorkspaceWindow] windowController];
#else
    return nil;
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
