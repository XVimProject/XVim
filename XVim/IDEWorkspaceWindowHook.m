//
//  IDEWorkspaceWindowHook.m
//  XVim
//
//  Created by Suzuki Shuichiro on 3/24/13.
//
//

#import "IDEKit.h"
#import "IDEWorkspaceWindowHook.h"
#import "Hooker.h"
#import "Logger.h"
#import "NSEvent+VimHelper.h"

@implementation IDEWorkspaceWindowHook
+(void)hook{
    [Hooker hookClass:@"IDEWorkspaceWindow" method:@"sendEvent:" byClass:@"IDEWorkspaceWindowHook" method:@"sendEvent:"];
}

-(void)sendEvent:(NSEvent*)event{
    IDEWorkspaceWindow* base = (IDEWorkspaceWindow*)self;
    if( event.type == NSKeyDown ){
        TRACE_LOG(@"Window:%p keyCode:%d characters:%@ charsIgnoreMod:%@ cASCII:%d", self, event.keyCode, event.characters, event.charactersIgnoringModifiers, event.unmodifiedKeyCode);
    }
    [base sendEvent_:event];
}
@end
