//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimKeymapProvider.h"
#import "XVimTextViewProtocol.h"
#import "XVimMode.h"

@class XVimKeymap;
@class XVimOptions;
@class XVimRegister;
@class XVimSearch;
@class XVimCharacterSearch;
@class XVimExCommand;
@class XVimHistoryHandler;
@class XVimCommandLine;
@class XVimCommandField;
@class XVimMarks;
@class XVimMotion;

extern NSString * const XVimDocumentChangedNotification;
extern NSString * const XVimDocumentPathKey;

@interface XVim : NSObject<XVimKeymapProvider>

+ (XVim*)instance;
@property (strong) XVimOptions* options;
@property (strong) XVimSearch* searcher;
@property (strong) XVimMotion* lastCharacterSearchMotion;
@property (strong) XVimExCommand* excmd;
@property (readonly) XVimMarks* marks;
@property (readonly) XVimRegisterManager* registerManager;
@property (strong,readonly) XVimMutableString *repeatRegister;
@property (weak) NSString* lastPlaybackRegister;
@property (strong) NSString* document;

- (XVimKeymap*)keymapForMode:(XVIM_MODE)mode;
- (void)parseRcFile;
- (XVimHistoryHandler*)exCommandHistory;
- (XVimHistoryHandler*)searchHistory;

/**
 * Repeat(.) command related methods.
 *
 * How to use:
 * Call appendRepeatKeyStroke to append repeat register.
 * (This is not real register but just XVimString)
 * When the command is fixed call fixRepeatCommand method.
 * This set XVim's repeatRegister property (until then it never changes)
 * If you want to cancel the input for the repeat call cancelRepeatCommand.
 *
 * This is because not all the key input should be recorded into
 * repeat command register but only edit commands should be stored.
 *
 * Whenever key input occurs key hanlder(XVimWindow) calls
 * appendRepeatKeyStroke method with the input.
 * When the command is fixed in edit command related evaluators
 * it calls fixRepeatCommand.
 * If it is not called and when a command(series of key input) is 
 * finished XVimWindow calls cancelRepeatCommand not to store the
 * key input recorded in repeat regisger so far.
 *
 * When repeating you must call startRepeat first and 
 * call endRepeat after you finish repeating.
 * When in repeating the key input never recorded into 
 * repeat regisgter
 **/
- (void)appendRepeatKeyStroke:(XVimString*)stroke;
- (void)fixRepeatCommand;
- (void)cancelRepeatCommand;
- (void)startRepeat;
- (void)endRepeat;

/**
 * Write string to debuger console.
 * It automatically inserts newline end of the string.
 * Do not use this for debugging XVim.
 * This is for XVim feature. Use TRACE_LOG or DEBUG_LOG to debug and Xcode as a debugger.
 **/
- (void)writeToConsole:(NSString*)fmt, ...;

- (void)ringBell;

@end
