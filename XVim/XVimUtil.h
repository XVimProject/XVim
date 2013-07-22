//
//  XVimUtil.h
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceWindowController;
@class IDEWorkspaceTabController;
@class IDEEditorArea;
@class DVTSourceTextView;
IDEWorkspaceWindowController* XVimLastActiveWindowController(void);
IDEWorkspaceTabController* XVimLastActiveWorkspaceTabController(void);
IDEEditorArea* XVimLastActiveEditorArea(void);
DVTSourceTextView* XVimLastActiveSourceView(void);

@interface XVimUtil : NSObject

@end
