//
//  XVimEditorArea.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/23/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDEKit.h"

@interface IDEEditorAreaHook : NSObject
+ (void)hook;
@end


@interface IDEEditorArea(Hook)
- (void)viewDidInstall_;
- (void)primitiveInvalidate_;
@end