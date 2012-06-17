//
//  XVimWindow+Xcode.m
//  XVim
//
//  Created by Ant on 17/06/2012.
//
//

#import "XVimWindow+Xcode.h"
#import "XVimSourceView+Xcode.h"
#import "IDEKit.h"

@implementation XVimWindow(Xcode)
-(void)becomeMainWindow
{
    [self.sourceView.window becomeMainWindow];
}
@end
