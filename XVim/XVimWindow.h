//
//  XVimBuffer.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//

#import <Cocoa/Cocoa.h>
#import "XVimMode.h"
#import "XVimCommandLine.h"
#import "XVimPlaybackHandler.h"

/*
 * This class manages 1 window. (The term "window" here is different from NSWindow)
 * A window has several text views and one command line view.
 *
 */

@class XVimSourceView;
@class XVimEvaluator;
@class XVimRegister;
@class IDEEditorArea;

@interface XVimWindow : NSObject <NSTextFieldDelegate, XVimCommandFieldDelegate, XVimPlaybackHandler>

//------- old impelementation will be replaced with other methods-----
@property(retain) XVimSourceView* sourceView;
@property(readonly) XVimEvaluator *currentEvaluator;
@property(retain) IDEEditorArea* editorArea;


- (NSUInteger)insertionPoint;
- (XVimCommandLine*)commandLine;

- (BOOL)handleKeyEvent:(NSEvent*)event;
- (void)beginMouseEvent:(NSEvent*)event;
- (void)endMouseEvent:(NSEvent*)event;
- (NSRange)restrictSelectedRange:(NSRange)range;
- (NSMutableDictionary *)getLocalMarks;

- (void)drawRect:(NSRect)rect;
- (BOOL)shouldDrawInsertionPoint;
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;


// XVimCommandFieldDelegate
- (void)commandFieldLostFocus:(XVimCommandField*)commandField;

// XVimPlaybackHandler
- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;
- (void)handleVisualMode:(VISUAL_MODE)mode withRange:(NSRange)range;

- (void)recordIntoRegister:(XVimRegister*)xregister;
- (void)stopRecordingRegister:(XVimRegister*)xregister;

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)clearErrorMessage;

+ (XVimWindow*)windowOfIDEEditorArea:(IDEEditorArea*)editorArea;
+ (void)createWindowForIDEEditorArea:(IDEEditorArea*)editorArea;

- (void)setForcusBackToSourceView;

@end
