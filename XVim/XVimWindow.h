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
 *
 * ----------------------   -----------------------
 *    XVimWindow class   ->  XVimWindow + Xcode
 * ----------------------   -----------------------
 *                           IDEEditorArea class
 *                          -----------------------
 *
 * XVimWindow uses XVimWindow + Xcode category.
 * XVimWindow + Xcode category depends on Xcode class (IDEEditorArea)
 */
@class XVimSourceView;
@class XVimEvaluator;
@class XVimRegister;

@interface XVimWindow : NSObject <NSTextFieldDelegate, XVimCommandFieldDelegate, XVimPlaybackHandler>

@property(retain) XVimSourceView* sourceView;
@property(readonly) XVimEvaluator *currentEvaluator;
@property(assign) XVimCommandLine *commandLine;

- (NSUInteger)insertionPoint;

- (BOOL)handleKeyEvent:(NSEvent*)event;
- (void)beginMouseEvent:(NSEvent*)event;
- (void)endMouseEvent:(NSEvent*)event;
- (NSRange)restrictSelectedRange:(NSRange)range;
- (NSMutableDictionary *)getLocalMarks;

- (void)drawRect:(NSRect)rect;
- (BOOL)shouldDrawInsertionPoint;
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color;

- (void)setEvaluator:(XVimEvaluator*)evaluator;

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

+ (XVimWindow*)windowOf:(id)object;
+ (void)registerAsWindow:(id)object;

@end
