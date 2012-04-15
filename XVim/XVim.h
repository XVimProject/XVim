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
@class XVimSourceCodeEditor;

@interface XVim : NSObject<XVimKeymapProvider>

+ (XVim*)instance;

@property (strong, readonly) NSDictionary* registers;
@property (strong) XVimOptions* options;
@property (strong) XVimSearch* searcher;
@property (strong) XVimCharacterSearch* characterSearcher;
@property (strong) XVimExCommand* excmd;
@property (weak) XVimSourceCodeEditor* editor;
@property (strong) XVimRegister *yankRegister;
@property (readonly) NSString* pasteText;

- (XVimKeymap*)keymapForMode:(int)mode;
- (XVimRegister*)findRegister:(NSString*)name;
- (void)parseRcFile;
- (NSString*)exCommandHistory:(NSUInteger)no withPrefix:(NSString*)str;
- (void)ringBell;
- (void)onDeleteOrYank;

@end
