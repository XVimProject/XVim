//
//  XVimUtil.h
//  XVim
//
//  Created by Suzuki Shuichiro on 4/1/13.
//
//

#import <Foundation/Foundation.h>
#import "DVTFoundation.h"
#import "DVTKit.H"
#import "IDEKit.h"

IDEWorkspaceWindowController* XVimLastActiveWindowController(void);
IDEEditorArea* XVimLastActiveEditorArea(void);
DVTSourceTextView* XVimLastActiveSourceView(void);

@interface XVimUtil : NSObject

@end
