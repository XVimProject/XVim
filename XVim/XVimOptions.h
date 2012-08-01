//
//  XVimOptions.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVimOptions : NSObject
@property BOOL ignorecase;
@property BOOL wrapscan;
@property BOOL errorbells;
@property BOOL incsearch;
@property BOOL gdefault;
@property BOOL smartcase;
@property BOOL debug;
@property (copy) NSString *guioptions;
@property (copy) NSString *timeoutlen;

- (id)getOption:(NSString*)name;
- (void)setOption:(NSString*)name value:(id)value;
@end
