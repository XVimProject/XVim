//
//  XVimSourceCodeEditor.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDESourceCodeEditor+XVim.h"

@interface IDEPlaygroundEditor : IDESourceCodeEditor
@end

@interface IDEPlaygroundEditor(XVim)
+ (void)xvim_initialize;

// The reason to append "2" at end of the method name is because this class is inheited from IDESourceCodeEdtior
// which we also swizzle. It interfares if we us the same name.
- (void)xvim_didSetupEditor2;

@end