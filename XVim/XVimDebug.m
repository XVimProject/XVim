//
//  XVimDebug.m
//  XVim
//
//  Created by Suzuki Shuichiro on 2/16/13.
//
//

#import "XVimDebug.h"
#import "Logger.h"

@implementation XVimDebug


- (void)ViewTree{
    [Logger traceView:[[[NSApplication sharedApplication] mainWindow] contentView] depth:0];
}
@end
