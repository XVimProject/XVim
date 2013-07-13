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


- (void)viewTree:(NSArray*)params{
    [Logger traceView:[[[NSApplication sharedApplication] mainWindow] contentView] depth:0];
}

- (void)trace:(NSArray*)params{
    if( params.count != 0 ){
        [Logger registerTracing:[params objectAtIndex:0]];
    }
}
@end
