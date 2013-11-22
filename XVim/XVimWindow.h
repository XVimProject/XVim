//
//  XVimWindow.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import <Cocoa/Cocoa.h>
#import "XVimCommandLine.h"
#import "XVimKeyStroke.h"
#import "XVimBuffer.h"
#import "XVimView.h"

/*
 * This class manages 1 window. (The term "window" here is different from NSWindow)
 * A window has several text views and one command line view.
 * All the key input (or mouse input or some other event if needed ) must be passed to
 * the associated XVimWindow object first and it handles the event.
 */

@class XVimEvaluator;
@class XVimRegister;
@class IDEEditorArea;
@class IDEWorkspaceWindow;
@class XVimEvaluatorContext;
@class IDEEditorArea;

@interface XVimWindow : NSObject <NSTextInputClient, NSTextFieldDelegate>
@property(nonatomic, readonly) XVimCommandLine *commandLine;
@property(nonatomic, readonly) XVimBuffer *currentBuffer;
@property(nonatomic, readonly) XVimView *currentView;

- (instancetype)initWithIDEEditorArea:(IDEEditorArea *)editorArea;

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke onStack:(NSMutableArray*)stack;
- (BOOL)handleKeyEvent:(NSEvent*)event;
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)statusMessage:(NSString*)message;
- (void)clearErrorMessage;

- (void)setForcusBackToSourceView;

- (IDEWorkspaceWindow*)currentWorkspaceWindow;

- (void)syncEvaluatorStack;

@end
