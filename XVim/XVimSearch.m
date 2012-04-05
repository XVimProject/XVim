//
//  XVimSearch.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearch.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"
#import "Logger.h"

@interface XVimSearch(){
    XVim* _xvim;
}
- (NSRange)searchForward;
- (NSRange)searchBackward;
@end

@implementation XVimSearch
@synthesize lastSearchBackword, lastSearchString, lastReplacementString, nextSearchBaseLocation, endOfReplacement;

- (id)initWithXVim:(XVim*)xvim{
    
    if( self = [super init] ){
        _xvim = [xvim retain];
        lastSearchString = @"";
        lastReplacementString = @"";
    }
    return self;
}

- (void)dealloc{
    [_xvim release];
    [super dealloc];
}

- (NSRange)executeSearch:(NSString*)searchCmd{
    unichar first = [searchCmd characterAtIndex:0];
    if( first == '?' ){
        self.lastSearchBackword = YES;
    }else if( first == '/' ){
        self.lastSearchBackword = NO;
    }else{
        NSAssert(NO, @"first letter of search command must be ? or /");
    }
    
    // in vi, if there's no search string. use the last one specified. like you do for 'n'
    if( [searchCmd length] > 1 ){
        self.lastSearchString = [searchCmd substringFromIndex:1];
    }
    return [self searchNext];
}

- (NSRange)searchNext{
    if( lastSearchBackword ){
        return [self searchBackward];
    }else{
        return [self searchForward];
    }
}

- (NSRange)searchPrev{
    if( lastSearchBackword ){
        return [self searchForward];
    }else{
        return [self searchBackward];
    }
}

- (NSRange)searchForward {
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    DVTSourceTextView* srcView = [_xvim sourceView];
    NSUInteger search_base = self.nextSearchBaseLocation;
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_xvim.options.ignorecase== TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:self.lastSearchString
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [_xvim statusMessage:[NSString stringWithFormat:
                             @"Cannot compile regular expression '%@'",self.lastSearchString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    // search text beyond the search_base
    if( [[srcView string] length]-1 > search_base){
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:r_opts
                                           range:NSMakeRange(search_base+1, [[srcView string] length] - search_base - 1)];
    }
    
    // if wrapscan is on, wrap to the top and search
    if (found.location == NSNotFound && _xvim.options.wrapscan== TRUE) {
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:r_opts
                                           range:NSMakeRange(0, [[srcView string] length])];
        [_xvim statusMessage:[NSString stringWithFormat:
                             @"Search wrapped for '%@'",self.lastSearchString] ringBell:TRUE];
    }
    
    if( found.location != NSNotFound ){
        // note: make sure this stays *after* setSelectedRange which also updates 
        // _nextSearchBaseLocation as a side effect
        self.nextSearchBaseLocation = found.location + ((found.length==0)? 0: found.length-1);
    }
    return found;
}


- (NSRange)searchBackward {
    // opts = (NSBackwardsSearch | NSRegularExpressionSearch) is not supported by [NSString rangeOfString:opts]
    // What we do instead is a search for all occurences and then
    // use the range of the last match. Not very efficient, but i don't think
    // optimization is warranted until slowness is experienced at the user level.
    DVTSourceTextView* srcView = [_xvim sourceView];
    NSUInteger search_base = self.nextSearchBaseLocation;
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_xvim.options.ignorecase == TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:self.lastSearchString
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [_xvim statusMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    NSArray*  matches = [regex matchesInString:[srcView string]
                                       options:r_opts
                                         range:NSMakeRange(0, [[srcView string] length]-1)];
    
    // search above base
    if (search_base > 0) {
        for (NSTextCheckingResult *match in matches) { // get last match in area before search_base
            NSRange tmp = [match range];
            if (tmp.location >= search_base)
                break;
            found = tmp;
        }
    }
    // if wrapscan is on, search below base as well
    if (found.location == NSNotFound && _xvim.options.wrapscan == TRUE) {
        if ([matches count] > 0) {
            NSTextCheckingResult *match = ([matches objectAtIndex:[matches count]-1]);
            found = [match range];
            [_xvim statusMessage:[NSString stringWithFormat: @"Search wrapped for '%@'",self.lastSearchString] ringBell:FALSE];
        }
    }
    if (found.location != NSNotFound) {
        [self setNextSearchBaseLocation:found.location];
    }
    return found;
}


- (NSRange)replaceForward{
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    NSTextView* srcView = (NSTextView*)[_xvim sourceView];
    NSRange found = {NSNotFound, 0};
    
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_xvim.options.ignorecase == YES) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    TRACE_LOG(@"%@", lastReplacementString);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:lastSearchString options:r_opts error:&error];
    
    if (error != nil) {
        [_xvim statusMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",lastSearchString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    // search text beyond the search_base
    found = [regex rangeOfFirstMatchInString:[srcView string] options:r_opts range:NSMakeRange(nextSearchBaseLocation, [[srcView string] length] - nextSearchBaseLocation)];
    
    if( found.location >= endOfReplacement ){
        return NSMakeRange(NSNotFound, 0);
    }
    if( found.location != NSNotFound){
        // Replace the text
        // The following method is undoable
        [srcView insertText:lastReplacementString replacementRange:found];
        // Move the next search base and end of replacement pos according to replaced and replacement test length
        nextSearchBaseLocation= found.location + [lastReplacementString length];
        endOfReplacement = endOfReplacement - (found.length) + [lastReplacementString length];
    }
    
    return found;
}

- (void)substitute:(NSString*)ex_command from:(NSUInteger)from to:(NSUInteger)to{
    // Split the string into the various components
    NSString* replaced = @"";
    NSString* replacement = @"";
    char previous = 0;
    int component = 0;
    BOOL global = NO;
    BOOL confirmation = NO;
    if ([ex_command length] >= 3) {
        for(int i=1;i<[ex_command length];++i) {
            char current = [ex_command characterAtIndex:i];
            if (current == '/' && previous != '\\') {
                component++;
            } else {
                if (component == 0) {
                    replaced = [NSString stringWithFormat:@"%@%c",replaced,current];
                } else if (component == 1) {
                    replacement = [NSString stringWithFormat:@"%@%c",replacement,current];
                } else {
                    if (current == 'g') {
                        global = YES;
                    } else if (current == 'c') {
                        confirmation = YES;
                    } else {
                        ERROR_LOG("Unknown replace option %c",current);
                    }
                }
                previous = current;
            }
        }
        TRACE_LOG("replaced=%@",replaced);
        TRACE_LOG("replacement=%@",replacement);
    }
    self.lastSearchString = replaced;
    self.lastReplacementString = replacement;
    
    // Find the position to start searching
    NSUInteger replace_start_location = [[_xvim sourceView] positionAtLineNumber:from column:0];
    if( NSNotFound == replace_start_location){
        return;
    }
    nextSearchBaseLocation = replace_start_location;
    
    // Find the position to end the searching
    endOfReplacement = [[_xvim sourceView] positionAtLineNumber:to+1 column:0]; // Next line of the end of range.
    if( NSNotFound == endOfReplacement ){
        endOfReplacement = [[[_xvim sourceView] string] length];
    }
    // This is lazy implementation.
    // When text is substituted the end location may be smaller or greater than original end position.
    // I'll implement correct version later.
    
    // Replace all the occurrences
    int numReplacements = 0;
    NSRange found;
    do {
        found = [self replaceForward];
        if (found.location != NSNotFound) {
            numReplacements++;
        }
    } while(found.location != NSNotFound && global && nextSearchBaseLocation < endOfReplacement);
    [_xvim statusMessage:[NSString stringWithFormat: @"Number of occurrences replaced %d",numReplacements] ringBell:TRUE];
    
}
@end
