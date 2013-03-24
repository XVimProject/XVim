//
//  XVimBuffer.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import <Cocoa/Cocoa.h>
#import "XVimMode.h"
#import "XVimCommandLine.h"
#import "XVimTextViewProtocol.h"
#import "XVimPlaybackHandler.h"
#import "XVimTextViewProtocol.h"

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

@interface XVimWindow : NSObject <NSTextFieldDelegate, XVimCommandFieldDelegate, XVimPlaybackHandler>

@property(strong) XVimSourceView<XVimTextViewProtocol>* sourceView; // This represents currently focused sourceView
@property(strong) IDEEditorArea* editorArea;

- (NSUInteger)insertionPoint; // May be removed. This should be accessed via sourceView::insertionPoint
- (XVimCommandLine*)commandLine;

- (BOOL)handleKeyEvent:(NSEvent*)event;
- (void)beginMouseEvent:(NSEvent*)event;
- (void)endMouseEvent:(NSEvent*)event;
- (NSRange)restrictSelectedRange:(NSRange)range;

- (void)drawRect:(NSRect)rect;
- (BOOL)shouldDrawInsertionPoint;
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;

- (void)mouseDown:(NSEvent*)event;
- (void)mouseUp:(NSEvent*)event;
- (void)mouseDragged:(NSEvent*)event;

// XVimCommandFieldDelegate
- (void)commandFieldLostFocus:(XVimCommandField*)commandField;

// XVimPlaybackHandler
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;
- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range;

- (void)recordIntoRegister:(XVimRegister*)xregister;
- (void)stopRecordingRegister:(XVimRegister*)xregister;

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)statusMessage:(NSString*)message;
- (void)clearErrorMessage;

+ (XVimWindow*)windowOfIDEEditorArea:(IDEEditorArea*)editorArea;
+ (void)createWindowForIDEEditorArea:(IDEEditorArea*)editorArea;

- (void)setForcusBackToSourceView;

- (IDEWorkspaceWindow*)currentWorkspaceWindow;

/**
 * Sync to update XVim internal state acording to Xcode state(mainly selected ranges).
 * This method must be called after you call Xcode operation.
 * It is usually Xcode operation like [NSApp sendAction] 
 * When you call such method Xcode changes state of source view.
 * This breaks integrity between infomation we keep internally and Xcode has internally.
 *
 * TODO:
 * For future:
 * We should not call Xcode functionarity directly without going through "XVimWindow" object.
 * All the command must go through XVimWindow or XVimSourceView and there we can keep the integrity.
 **/
- (void)syncState;

@end
