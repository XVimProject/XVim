//
//  XVimDebug.m
//  XVim
//
//  Created by Suzuki Shuichiro on 2/16/13.
//
//

#import "XVimDebug.h"
#import "XVimWindow.h"
#import "Logger.h"

// You can invoke methods in this class by
// ":debug xxxx [args]" where xxx is a method name.
// [args] will be passed as "params" array by separating with space.

@implementation XVimDebug

- (void)viewTree:(NSArray*)params withWindow:(XVimWindow*)window{
    [Logger traceView:[[[NSApplication sharedApplication] mainWindow] contentView] depth:0];
}

- (void)trace:(NSArray*)params withWindow:(XVimWindow*)window{
    if( params.count != 0 ){
        [Logger registerTracing:[params objectAtIndex:0]];
    }
}

- (void)highlight:(NSArray*)params withWindow:(XVimWindow*)window{
    NSTextView* view = window.sourceView;
    [[view textStorage] beginEditing];
    [[view textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:NSMakeRange(0,5)];
    [[view textStorage] endEditing];
}

- (void)highlightclear:(NSArray*)params withWindow:(XVimWindow*)window{
    NSTextView* view = window.sourceView;
    [[view textStorage] beginEditing];
    [[view textStorage] addAttribute:NSBackgroundColorAttributeName value:[NSColor clearColor] range:NSMakeRange(0, view.string.length)];
    [[view textStorage] endEditing];
}
@end
