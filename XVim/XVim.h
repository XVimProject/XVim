//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimDefs.h"
#import "XVimKeymapProvider.h"
#import "XVimTextViewProtocol.h"
#import "XVimKeyStroke.h"

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
@class XVimRegisterManager;


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
@property (readonly) XVimHistoryHandler* exCommandHistory;
@property (readonly) XVimHistoryHandler* searchHistory;
@property (readonly) XVimMutableString *lastOperationCommands;
@property  XVIM_VISUAL_MODE lastVisualMode;
@property  XVimPosition lastVisualPosition;
@property  XVimPosition lastVisualSelectionBegin;
@property (nonatomic) BOOL isRepeating; // For dot(.) command repeat

@property (copy) NSString* lastPlaybackRegister;
@property (copy) NSString* document;
@property (nonatomic) BOOL isExecuting; // For @x command executing

// XVimKeymapProvider protocol
- (XVimKeymap*)keymapForMode:(XVIM_MODE)mode;

/**
 * Repeat(.) command related methods.
 *
 * How to use:
 * Call appendOperationKeyStroke to append operation commands.
 * Until you call fixOperationCommand it is saved int temporary buffer.
 * When the command is fixed call fixOperationCommand method.
 * This saves the commands to lastOperationCommands property.
 * If you want to cancel the command call cancelOperationCommands.
 *
 * This is because not all the key input should be recorded into
 * repeat command register but only edit commands should be stored.
 *
 * Whenever key input occurs key hanlder(XVimWindow) calls
 * appendOperationKeyStroke method with the input.
 * When the command is fixed with edit command related evaluators
 * it calls fixOperationCommand.
 * If it is not called and when a command(series of key input) is 
 * finished XVimWindow calls cancelRepeatCommand not to store the
 * key input recorded in repeat regisger so far.
 *
 * When repeating you must call startRepeat first and 
 * call endRepeat after you finish repeating.
 * When in repeating the key input never recorded into 
 * repeat regisgter
 **/
- (void)appendOperationKeyStroke:(XVimString*)stroke;
- (void)fixOperationCommands;
- (void)cancelOperationCommands;
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
