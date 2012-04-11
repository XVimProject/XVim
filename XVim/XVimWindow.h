//
//  XVimBuffer.h
//  XVim
//
//  Created by Tomas Lundell on 9/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XVimMode.h"
#import "XVimCommandLine.h"
#import "XVimPlaybackHandler.h"

@class DVTSourceTextView;
@class XVimEvaluator;
@class XVimRegister;

#define XVIM_TAG 1209 // This is Shu's birthday!

@interface XVimWindow : NSTextView <NSTextFieldDelegate, XVimCommandFieldDelegate, XVimPlaybackHandler>

@property NSInteger tag;
@property (readonly) NSInteger mode;

@property(retain) DVTSourceTextView* sourceView;
@property(readonly) XVimEvaluator *currentEvaluator;
@property(weak, readonly) XVimRegister *recordingRegister;

@property(retain) XVimCommandLine* cmdLine;
@property (strong) NSString* staticMessage;
@property (strong) NSString* errorMessage;

- (void)commandModeWithFirstLetter:(NSString*)first;
- (NSString*)modeName;

- (NSString*)sourceText;
- (NSRange)selectedRange;
- (NSUInteger)cursorLocation; // Same as selectedRange.location

- (BOOL)handleKeyEvent:(NSEvent*)event;
- (void)beginMouseEvent:(NSEvent*)event;
- (void)endMouseEvent:(NSEvent*)event;
- (NSRange)restrictSelectedRange:(NSRange)range;
- (NSMutableDictionary *)getLocalMarks;

- (void)setEvaluator:(XVimEvaluator*)evaluator;

// Message from XVimCommandField 
- (BOOL)commandCanceled;
- (BOOL)commandFixed:(NSString*)command;

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke;
- (void)handleTextInsertion:(NSString*)text;

- (void)errorMessage:(NSString *)message ringBell:(BOOL)ringBell;
- (void)ringBell;
- (void)recordIntoRegister:(XVimRegister*)xregister;
- (void)stopRecordingRegister:(XVimRegister*)xregister;
- (void)playbackRegister:(XVimRegister*)xregister withRepeatCount:(NSUInteger)count;

@end
