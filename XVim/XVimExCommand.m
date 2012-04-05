//
//  XVimExCommand.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerSHu.Net. All rights reserved.
//

#import "XVim.h"
#import "DVTSourceTextView.h"
#import "XVimExCommand.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"

@implementation XVimExArg
@synthesize arg,cmd,forceit,lineBegin,lineEnd,addr_count;
@end

@implementation XVimExCmdname
@synthesize cmdName,methodName;

-(id)initWithCmd:(NSString*)cmd method:(NSString*)method{
    if( self = [super init] ){
        cmdName = [cmd retain];
        methodName = [method retain];
    }
    return self;
}
@end


@implementation XVimExCommand

#define CMD(cmd,mtd) [[XVimExCmdname alloc] initWithCmd:cmd method:mtd]
-(id)initWithXVim:(XVim*)xvim{
    if( self = [super init] ){
        // This is the ex command list.
        // This is a subset of the list from ex_cmds.h in Vim source code.
        // As in ex_cmds.h the order of the command is important.
        // The method names correspond the Vim's function name.
        
        _excommands = [[NSArray alloc] initWithObjects:
                   CMD(@"substitute", @"sub:"),
                   CMD(@"set", @"set:"),
                   CMD(@"write", @"write:"),
                   CMD(@"wq", @"exit:"),
                   CMD(@"quit", @"quit:"),                                        
                   CMD(@"debug", @"debug:"),
                   CMD(@"make", @"make:"),  // The following 2 are original to XVim
                   CMD(@"run", @"run:"),
                   nil];
        _xvim = [xvim retain];
    }
    return self;
}

- (void)dealloc{
    [_excommands release];
    [_xvim release];
    [super dealloc];
}

// This method correnspons parsing part of get_address in ex_cmds.c
- (NSUInteger)getAddress:(unichar*)parsing :(unichar**)cmdLeft{
    DVTSourceTextView* view = [_xvim sourceView];
    DVTFoldingTextStorage* storage = [view textStorage];
    TRACE_LOG(@"Storage Class:%@", NSStringFromClass([storage class]));
    NSUInteger addr = NSNotFound;
    NSUInteger begin = [view selectedRange].location;
    NSUInteger end = [view selectedRange].location + [view selectedRange].length-1;
    unichar* tmp;
    NSUInteger count;
    unichar mark;
    
    // Parse base addr (line number)
    switch (*parsing)
    {
        case '.':
            parsing++;
            addr = [view lineNumber:begin];
            break;
        case '$':			    /* '$' - last line */
            parsing++;
            addr = [view numberOfLines];
            break;
        case '\'':
            // XVim does support only '< '> marks for visual mode
            mark = parsing[1];
            if( '<' == mark ){
                addr = [view lineNumber:begin];
                parsing+=2;
            }else if( '>' == mark ){
                addr = [view lineNumber:end];
                parsing+=2;
            }else{
                // Other marks or invalid character. XVim does not support this.
            }
            break;
        case '/':
        case '?':
        case '\\':
            // XVim does not support using search in range at the moment
            // XVim does not support using search in range at the moment
        default:
            tmp = parsing;
            count = 0;
            while( isDigit(*parsing) ){
                parsing++;
                count++;
            }
            addr = [[NSString stringWithCharacters:tmp length:count] intValue];
            if( 0 == addr ){
                addr = NSNotFound;
            }
    }
    
    // Parse additional modifier for addr ( ex. $-10 means 10 line above from end of file. Parse '-10' part here )
    for (;;)
    {
        // Skip whitespaces
        while( isWhiteSpace(*parsing) ){
            parsing++;
        }
        
        unichar c = *parsing;
        unichar i;
        NSUInteger n;
        if (c != '-' && c != '+' && !isDigit(c)) // Handle '-' or '+' or degits only
            break;
        
        if (addr == NSNotFound){
            //addr = [view lineNumber:begin]; // This should be current cursor posotion
        }
        
        // Determine if its + or -
        if (isDigit(c)){
            i = '+';		/* "number" is same as "+number" */
        }else{
            i = c;
            parsing++;
        }
        
        if (!isDigit(*parsing)){	/* '+' is '+1', but '+0' is not '+1' */
            n = 1;
        }
        else{
            tmp = parsing;
            count = 0;
            while( isDigit(*parsing) ){
                parsing++;
                count++;
            }
            n = [[NSString stringWithCharacters:tmp length:count] intValue];
        }
        
        // Calc the address from base
        if (i == '-')
            addr -= n;
        else
            addr += n;
    }
    
    *cmdLeft = parsing;
    return addr;
}

// This method correnspons parsing part of do_one_cmd in ex_docmd.c in Vim
// What Vim does in this function is followings
/*
 * 1. skip comment lines and leading space
 * 2. handle command modifiers
 * 3. parse range
 * 4. parse command
 * 5. parse arguments
 * 6. switch on command name
 */

/*
 * But XVim implements minimum set of above processes at thee moment
 * Command line XVim supports are following format
 *     [range][command] [arguments]
 * [range] is [addr][,addr][,addr]...     separated by ';' is not supported at the moment
 * [addr] only supports digits or %,.,$,'<,'>, and +- modifiers
 * Multiple commands separated by '|' is not supported at the moment
 * Space is needed between [command] and [arguments]
 * 
 */

- (XVimExArg*)parseCommand:(NSString*)cmd{
    DVTSourceTextView* view = [_xvim sourceView];
    XVimExArg* exarg = [[[XVimExArg alloc] init] autorelease]; 
    NSUInteger len = [cmd length];
    
    // Create unichar array to parse. Its easier
    NSMutableData* dataCmd = [NSMutableData dataWithLength:(len+1)*sizeof(unichar)];
    unichar* pCmd = (unichar*)[dataCmd bytes];
    [cmd getCharacters:pCmd range:NSMakeRange(0,len)];
    pCmd[len] = 0; // NULL terminate
     
    unichar* parsing = pCmd;
    
    // 1. skip comment lines and leading space ( XVim does not handling commnet lines )
    for( NSUInteger i = 0; i < len && ( isWhiteSpace(*parsing) || *parsing == ':' ); i++,parsing++ );
    
    // 2. handle command modifiers
    // XVim does not support command mofifiers at the moment
    
    // 3. parse range
    exarg.lineBegin = NSNotFound;
    exarg.lineEnd = NSNotFound;
    for(;;){
        NSUInteger addr = [self getAddress:parsing :&parsing];
        if( NSNotFound == addr ){
            if( *parsing == '%' ){ // XVim only supports %
                exarg.lineBegin = 1;
                exarg.lineEnd = [view numberOfLines];
                parsing++;
            }
        }else{
            exarg.lineEnd = addr;
        }
        
        if( exarg.lineBegin == NSNotFound ){ // If its first range 
            exarg.lineBegin = exarg.lineEnd;
        }
        
        if( *parsing != ',' ){
            break;
        }
        
        parsing++;
    }
    
    if( exarg.lineBegin == NSNotFound ){
        // No range expression found. Use current line as range
        exarg.lineBegin = [view lineNumber:[view selectedRange].location];
        exarg.lineEnd =  exarg.lineBegin;
    }
    
    // 4. parse command
    // In xvim command and its argument must be separeted by space
    unichar* tmp = parsing;
    NSUInteger count = 0;
    while( isAlpha(*parsing) || *parsing == '!' ){
        parsing++;
        count++;
    }

    if( 0 != count ){
        exarg.cmd = [NSString stringWithCharacters:tmp length:count];
    }else{
        // no command
        exarg.cmd = nil;
    }
    
    while( isWhiteSpace(*parsing)  ){
        parsing++;
    }
    
    // 5. parse arguments
    tmp = parsing;
    count = 0;
    while( *parsing != 0 ){
        count++;
        parsing++;
    }
    if( 0 != count ){
        exarg.arg = [NSString stringWithCharacters:tmp length:count];
    }else{
        // no command
        exarg.arg = nil;
    }
    
    return exarg;
}

// This method corresponds to do_one_cmd in ex_docmd.c in Vim
- (void)executeCommand:(NSString*)cmd{
    // cmd INCLUDE ":" character
    
    DVTSourceTextView* srcView = [_xvim sourceView];
    if( [cmd length] == 0 ){
        ERROR_LOG(@"command string empty");
        return;
    }
          
    // Actual parsing is done in following method.
    XVimExArg* exarg = [self parseCommand:cmd];
    if( exarg.cmd == nil ){
        // Jump to location
        NSUInteger pos = [srcView positionAtLineNumber:exarg.lineBegin column:0];
        NSUInteger pos_wo_space = [srcView nextNonBlankInALine:pos];
        if( NSNotFound == pos_wo_space ){
            pos_wo_space = pos;
        }
        [srcView setSelectedRange:NSMakeRange(pos_wo_space,0)];
        [srcView scrollToCursor];
        return;
    }
    
    // switch on command name
    for( XVimExCmdname* cmdname in _excommands ){
        if( [cmdname.cmdName hasPrefix:[exarg cmd]] ){
            SEL method = NSSelectorFromString(cmdname.methodName);
            if( [self respondsToSelector:method] ){
                [self performSelector:method withObject:exarg];
                break;
            }
        }
    }
    
    return;
}

///////////////////
//   Commands    //
///////////////////

- (void)sub:(XVimExArg*)args{
    [[_xvim searcher] substitute:args.arg from:args.lineBegin to:args.lineEnd];
}

- (void)set:(XVimExArg*)args{
    NSString* setCommand = [args.arg stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    DVTSourceTextView* srcView = [_xvim sourceView];
    
    if( [setCommand rangeOfString:@"="].location != NSNotFound ){
        // "set XXX=YYY" form
        
    }else if( [setCommand hasPrefix:@"no"] ){
        // "set noXXX" form
        NSString* prop = [setCommand substringFromIndex:2];
        [_xvim.options setOption:prop value:[NSNumber numberWithBool:NO]];
    }else{
        // "set XXX" form
        [_xvim.options setOption:setCommand value:[NSNumber numberWithBool:YES]];
    }
    
    if( [setCommand isEqualToString:@"wrap"] ){
        [srcView setWrapsLines:YES];
    }
    else if( [setCommand isEqualToString:@"nowrap"] ){
        [srcView setWrapsLines:NO];
    }                
}

- (void)write:(XVimExArg*)args{ // :w
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
}

- (void)exit:(XVimExArg*)args{ // :wq
    [NSApp sendAction:@selector(saveDocument:) to:nil from:self];
    [NSApp terminate:self];
}

- (void)quit:(XVimExArg*)args{ // :q
    [NSApp terminate:self];
}

- (void)debug:(NSString*)args{
}

- (void)make:(NSString*)args{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"b" charactersIgnoringModifiers:@"b" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

- (void)run:(NSString*)args{
    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"r" charactersIgnoringModifiers:@"r" isARepeat:NO keyCode:1];
    [[NSApplication sharedApplication] sendEvent:keyPress];
}

// Following commands are useful and expected to be implemented but not working now.

//- (void)bn:(NSString*)args{
//    // Not supported at the moment
//    // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
//    // TODO: set first responder to the new DVTSourceTextView after switching tabs.
//    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
//    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:/*{*/@"}" charactersIgnoringModifiers:/*{*/@"}" isARepeat:NO keyCode:1];
//    
//    [[NSApplication sharedApplication] sendEvent:keyPress];
//}
//
//- (void)bp:(NSString*)args{
//    // Not supported at the moment
//    // Dosen't work as I intend... This switches between tabs but the focus doesnt gose to the DVTSorceTextView after switching...
//    // TODO: set first responder to the new DVTSourceTextView after switching tabs.
//    NSWindow *activeWindow = [[NSApplication sharedApplication] mainWindow];
//    NSEvent *keyPress = [NSEvent keyEventWithType:NSKeyDown location:[NSEvent mouseLocation] modifierFlags:NSCommandKeyMask timestamp:[[NSDate date] timeIntervalSince1970] windowNumber:[activeWindow windowNumber] context:[NSGraphicsContext graphicsContextWithWindow:activeWindow] characters:@"{"/*}*/ charactersIgnoringModifiers:@"{"/*}*/ isARepeat:NO keyCode:1];
//    [[NSApplication sharedApplication] sendEvent:keyPress];
//}

@end
