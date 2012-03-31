//
//  XVimExCommand.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//



// This is unfinished switchover from XVim.m.

#import "XVimExCommand.h"
#import "Logger.h"

@implementation XVimExCommand

-(id)init{
    if( self = [super init] ){
        // This is the ex command list.
        // This is a subset of the list from ex_cmds.h in Vim source code.
        // As in ex_cmds.h the order of the command is important.
        // The method names correspond the Vim's function name.
        
        _excommands = [[NSDictionary alloc] initWithObjectsAndKeys:
                   @"substitute", @"sub:"
                   @"set", @"set:",
                   @"write", @"wright:",
                   @"wq", @"exit:",
                   @"quit", @"quit:",
                    
                   
                   nil];
    }
    return self;
}

- (void)dealloc{
    [_excommands release];
    [super dealloc];
}

- (void)executeCommand:(NSString*)cmd withXVim:(XVim*)xvim{
    // cmd does not include ":" character
    NSString* c = [cmd stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    TRACE_LOG(@"command : %@", c);
    
    NSTextView* srcView = (NSTextView*)[self superview]; // DVTTextSourceView
    if( [c length] == 0 ){
        // Something wrong
        ERROR_LOG(@"command string empty");
    }
    else if( [c characterAtIndex:0] == ':' ){
        // ex commands (is it right?)
        NSString* ex_command;
        if( [c length] > 1 ){
            ex_command = [[c substringFromIndex:1] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }else{
            ex_command = @"";
        }
        NSCharacterSet *words_cs = [NSCharacterSet whitespaceAndNewlineCharacterSet];
        NSArray* words = [ex_command componentsSeparatedByCharactersInSet:words_cs];            
        NSUInteger words_count = [words count];
        int scanned_int_arg = -1;
        TRACE_LOG(@"EX COMMAND:%@, word count = %d", ex_command, words_count);
        
        // check to see if it's a simple ":NNN" ( go-line-NNN command )
    }   
}


@end
