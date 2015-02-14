//
//  DVTSourceTextView.h
//  XVim
//
//  Created by Tomas Lundell on 31/03/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "DVTKit.h"
#import "XVimWindow.h"
#import "IDEKit.h"

@class DVTSourceTextView;
@class XVimStatusLine;

/*
@interface DVTSourceTextViewHook : NSObject
+ (void)hook;
+ (void)unhook;
@end
 */

@interface DVTSourceTextView(XVim)
+ (void)xvim_initialize;
+ (void)xvim_finalize;

#pragma mark XVim Hook Methods
- (void)xvim_setSelectedRanges:(NSArray*)array affinity:(NSSelectionAffinity)affinity stillSelecting:(BOOL)flag;
- (void)xvim_selectAll:(id)sender;
- (void)xvim_paste:(id)sender;
- (void)xvim_delete:(id)sender;
- (void)xvim_keyDown:(NSEvent *)theEvent;
- (void)xvim_mouseDown:(NSEvent *)theEvent;
- (void)xvim_drawRect:(NSRect)dirtyRect;
- (void)xvim__drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor; // double underscore (__) is intentional. This is hook for "_drawInsertion..." method.
- (void)xvim_drawInsertionPointInRect:(NSRect)aRect color:(NSColor*)aColor turnedOn:(BOOL)flag;
- (void)xvim_didChangeText;
- (void)xvim_viewDidMoveToSuperview;
- (void)xvim_observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context;
- (BOOL)xvim_shouldAutoCompleteAtLocation:(unsigned long long)arg1;

#pragma mark XVim Category Methods
- (IDEEditorArea*)xvim_editorArea;
- (XVimWindow*)xvim_window;

#pragma Declaration for private methods (To suppress error by ARC)
- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;
@end