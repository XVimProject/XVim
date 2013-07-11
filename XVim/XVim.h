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
@property (weak) XVimRegister *repeatRegister;
@property (weak) NSString* lastPlaybackRegister;
@property (strong) NSString* document;

- (XVimKeymap*)keymapForMode:(int)mode;
- (void)parseRcFile;
- (XVimHistoryHandler*)exCommandHistory;
- (XVimHistoryHandler*)searchHistory;
- (void)ringBell;

@end
