//
//  IDESourceCodeEditor.h
//  XVim
//
//  Created by Tomas Lundell on 1/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@class IDEWorkspaceTabController;

@interface IDESourceCodeEditor : NSObject
- (NSView*)view;
- (IDEWorkspaceTabController*)workspaceTabController;
- (id)initWithNibName_:(NSString*)nibName bundle:(NSBundle*)nibBundle document:(NSDocument*)nibDocument;
- (NSRange)textView_:(NSTextView *)textView willChangeSelectionFromCharacterRange:(NSRange)oldSelectedCharRange toCharacterRange:(NSRange)newSelectedCharRange;
@end
