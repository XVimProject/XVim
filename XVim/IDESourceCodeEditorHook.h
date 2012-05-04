//
//  XVimSourceCodeEditor.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "IDESourceEditor.h"
@interface IDESourceCodeEditorHook : NSObject
+ (void)hook;
@end

@interface IDESourceCodeEditor(Hook)
- (id)initWithNibName_:nibName bundle:nibBundle document:nibDocument;
@end