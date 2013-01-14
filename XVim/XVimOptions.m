//
//  XVimOptions.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOptions.h"

@interface XVimOptions() {
@private
    NSDictionary* _option_maps;
}
@end

@implementation XVimOptions
@synthesize ignorecase = _ignorecase;
@synthesize wrapscan = _wrapscan;
@synthesize errorbells = _errorbells;
@synthesize incsearch = _incsearch;
@synthesize gdefault = _gdefault;
@synthesize smartcase = _smartcase;
@synthesize pasteboard = _pasteboard;
@synthesize guioptions = _guioptions;
@synthesize debug = _debug;
@synthesize timeoutlen = _timeoutlen;
@synthesize laststatus = _laststatus;

- (id)init{
    if( self = [super init] ){
        // Abbreviation mapping
        _option_maps =
        [[NSDictionary alloc] initWithObjectsAndKeys:
         @"ignorecase",@"ic",
         @"wrapscan",@"ws",
         @"errorbells",@"eb",
         @"incsearch",@"is",
         @"gdefault",@"gd",
         @"smartcase",@"scs",
         @"pasteboard",@"pb",
         @"timeoutlen",@"tm",
         @"laststatus",@"ls",
         nil];
        
        // Default values
        _ignorecase = NO;
        _wrapscan = YES;
        _errorbells = NO;
        _incsearch = YES;
		_gdefault = NO;
		_smartcase = NO;
		_pasteboard = NO;
		_guioptions = @"rb";
        _timeoutlen = @"1000";
        _laststatus = 2;
    }
    return self;
}

- (void)dealloc{
    [_option_maps release];
    [super dealloc];
}

- (id)getOption:(NSString*)name{
    NSString* propName = name;
    if( [_option_maps objectForKey:name] ){
        // If the name is abbriviation use full name
        propName = [_option_maps objectForKey:name];
    }
    if( [self respondsToSelector:NSSelectorFromString(propName)] ){
        return [self valueForKey:propName];
    }else{
        return nil;
    }
}

- (void)setOption:(NSString*)name value:(id)value{
    NSString* propName = name;
    if( [_option_maps objectForKey:name] ){
        // If the name is abbriviation use full name
        propName = [_option_maps objectForKey:name];
    }
    
    if( [self respondsToSelector:NSSelectorFromString(propName)] ){
        [self setValue:value forKey:propName];
    }
}

@end