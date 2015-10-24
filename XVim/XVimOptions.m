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

@synthesize number = _number;

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
         @"relativenumber", @"rn",
         @"alwaysuseinputsource", @"auis",
         @"blinkcursor", @"bc",
         @"startofline", @"sol",
         @"expandtab", @"et",
         @"highlight", @"hi",
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
        _relativenumber = NO;
        _alwaysuseinputsource = NO;
        _blinkcursor = NO;
        _startofline = YES;
        _expandtab = YES;
        self.highlight = @{@"Search": @{
                                   @"guibg": [NSColor yellowColor],
                                   }
                           };
    }
    return self;
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
    BOOL toggle = NO;
    NSRange range = [name rangeOfString:@"!"];
    if( range.location == name.length - 1 && name.length > 1 ){
        toggle = YES;
        name = [name substringToIndex:name.length - 1];
    }
    NSString* propName = name;
    if( [_option_maps objectForKey:name] ){
        // If the name is abbriviation use full name
        propName = [_option_maps objectForKey:name];
    }
    
    if( [self respondsToSelector:NSSelectorFromString(propName)] ){
        if( toggle ){
            id oldValue = [self valueForKey:propName];
            // Check if the old value was a BOOL
            if( strcmp([oldValue objCType], @encode(BOOL)) == 0 ){
                [self setValue:@(![oldValue boolValue]) forKey:propName];
                return;
            }
        }
        [self setValue:value forKey:propName];
    }
}

- (BOOL)number
{
    return _number;
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
