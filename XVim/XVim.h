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

@interface XVim : NSObject<XVimKeymapProvider>

+ (XVim*)instance;

@property(strong, readonly) NSSet* registers;
@property (strong) XVimOptions* options;
@property (strong) XVimSearch* searcher;
@property (strong) XVimCharacterSearch* characterSearcher;
@property (strong) XVimExCommand* excmd;

- (XVimKeymap*)keymapForMode:(int)mode;
- (XVimRegister*)findRegister:(NSString*)name;
- (void)parseRcFile;

@end
