//
//  IDEWorkspaceTabController+XVim.h
//  XVim
//
//  Created by Suzuki Shuichiro on 10/23/14.
//
//

#import "IDEKit.h"

@interface IDEWorkspaceTabController (XVim)
- (void)xvim_jumpFocus:(NSInteger)count relative:(BOOL)relative;
- (void)xvim_addEditor;
- (void)xvim_addEditorVertically;
- (void)xvim_addEditorHorizontally;
- (void)xvim_moveFocusDown;
- (void)xvim_moveFocusUp;
- (void)xvim_moveFocusLeft;
- (void)xvim_moveFocusRight;
- (void)xvim_removeAssistantEditor;
- (void)xvim_closeOtherEditors;
- (void)xvim_closeCurrentEditor;
@end
