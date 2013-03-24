//
//  IDEWorkspaceWindowHook.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//
//

#import <Foundation/Foundation.h>

@interface IDEWorkspaceWindowHook : NSObject
+(void)hook;
@end

@interface IDEWorkspaceWindow(hook)
- (void)sendEvent_:(NSEvent*)event;
@end