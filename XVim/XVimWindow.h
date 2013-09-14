//
//  XVimWindow.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import <Cocoa/Cocoa.h>
#import "XVimCommandLine.h"
#import "XVimTextViewProtocol.h"
#import "XVimKeyStroke.h"

/*
 * This class manages 1 window. (The term "window" here is different from NSWindow)
 * A window has several text views and one command line view.
 * All the key input (or mouse input or some other event if needed ) must be passed to
 * the associated XVimWindow object first and it handles the event.
 */

@class XVimSourceView;
@class XVimEvaluator;
@class XVimRegister;
@class IDEEditorArea;
@class IDEWorkspaceWindow;
@class XVimEvaluatorContext;

@interface XVimWindow : NSObject <NSTextInputClient, NSTextFieldDelegate>

@property(readonly) NSTextView* sourceView; // This represents currently focused sourceView

- (XVimCommandLine*)commandLine;

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke onStack:(NSMutableArray*)stack;
- (BOOL)handleKeyEvent:(NSEvent*)event;
- (BOOL)handleXVimString:(XVimString*)strokes;
- (NSRect)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;

- (void)mouseDown:(NSEvent*)event;

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)statusMessage:(NSString*)message;
- (void)clearErrorMessage;

+ (XVimWindow*)windowOfIDEEditorArea:(IDEEditorArea*)editorArea;
+ (void)createWindowForIDEEditorArea:(IDEEditorArea*)editorArea;

- (void)setForcusBackToSourceView;

- (IDEWorkspaceWindow*)currentWorkspaceWindow;


@end
