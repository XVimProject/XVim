//
//  XVimOptions.m
//  XVim
//
//  Created by Shuichiro Suzuki on 4/6/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimOptions.h"
#import "DVTFoundation.h"

@interface XVimOptions() {
@private
    NSDictionary* _option_maps;
}
@end

@implementation XVimOptions

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
         @"clipboard",@"cb",
         @"timeoutlen",@"tm",
         @"laststatus",@"ls",
         @"hlsearch",@"hls",
         @"number", @"nu",
         @"vimregex", @"vr",
         nil];
        
        // Default values
        _ignorecase = NO;
        _wrapscan = YES;
        _errorbells = NO;
        _incsearch = YES;
		_gdefault = NO;
		_smartcase = NO;
		_clipboard = @"";
		_guioptions = @"rb";
        _timeoutlen = @"1000";
        _laststatus = 2;
        _hlsearch = NO;
        _number = NO;
        _vimregex = NO;
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


- (void)setNumber:(BOOL)n{
    _number = n;
    [[DVTTextPreferences preferences] setShowLineNumbers:_number];
    
    
    // The following code is just to remember what I have tried and not worked to change preferences
    /*
    // This is tu get preference window controller (
    IDEPreferencesController* ctrl = [IDEPreferencesController defaultPreferencesController];
    TRACE_LOG(@"%@", [ctrl toolbarAllowedItemIdentifiers:nil]);
    
    // Directly manipulate user defaults does not work (It can change the value but not applied to currently existing views)
    NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];
    [defaults setBool:n forKey:@"DVTTextShowLineNumbers"];
    [defaults synchronize];
    [[NSApplication sharedApplication] setWindowsNeedUpdate:YES];
    [[NSApplication sharedApplication] updateWindows];
    [[IDEApplicationController sharedAppController] _currentPreferenceSetChanged];
    */
    
}

// Helper Methods

- (BOOL)clipboardHasUnnamed{
    return [self.clipboard rangeOfString:@"unnamed"].location != NSNotFound;
}

@end