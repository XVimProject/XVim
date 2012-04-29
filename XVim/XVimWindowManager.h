//
//  XVimWindowManager.h
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDESourceCodeEditor;

@interface XVimWindowManager : NSObject
+ (void)createWithEditor:(IDESourceCodeEditor*)editor;
+ (XVimWindowManager*)instance;
- (void)addEditorWindow;
- (void)addEditorWindowVertical;
- (void)addEditorWindowHorizontal;
- (void)removeEditorWindow;
- (void)closeAllButActive;
@end
