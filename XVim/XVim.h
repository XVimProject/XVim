//
//  XVim.h
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimKeymapProvider.h"

@class XVimKeymap;
@class XVimOptions;
@class XVimRegister;
@class XVimSearch;
@class XVimCharacterSearch;
@class XVimExCommand;
@class XVimHistoryHandler;
@class XVimCommandLine;
@class XVimCommandField;

@interface XVim : NSObject<XVimKeymapProvider>

+ (XVim*)instance;

@property (strong) XVimOptions* options;
@property (strong) XVimSearch* searcher;
@property (strong) XVimCharacterSearch* characterSearcher;
@property (strong) XVimExCommand* excmd;
@property (strong, readonly) NSDictionary* registers;
@property (weak) XVimRegister *repeatRegister;
@property (weak) XVimRegister *recordingRegister;
@property (weak) XVimRegister *lastPlaybackRegister;

- (XVimKeymap*)keymapForMode:(int)mode;
- (XVimRegister*)findRegister:(NSString*)name;
- (void)parseRcFile;
- (XVimHistoryHandler*)exCommandHistory;
- (XVimHistoryHandler*)searchHistory;
- (void)ringBell;
- (void)onDeleteOrYank:(XVimRegister*)yankRegister;
- (NSString*)pasteText:(XVimRegister*)yankRegister;
- (void)writeToLogfile:(NSString*)str;
    
@end
