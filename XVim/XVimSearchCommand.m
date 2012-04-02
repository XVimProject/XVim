//
//  XVImSearchCommand.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVImSearchCommand.h"
#import "NSTextView+VimMotion.h"
#import "XVim.h"

@interface XVimSearchCommand(){
    XVim* _xvim;
}
- (NSRange)searchForward;
- (NSRange)searchBackward;
@end

@implementation XVimSearchCommand
@synthesize lastSearchBackword, lastSearchString, nextSearchBaseLocation;

- (id)initWithXVim:(XVim*)xvim{
    
    if( self = [super init] ){
        _xvim = [xvim retain];
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
    
    NSTextView* srcView = [_xvim sourceView];
    NSUInteger search_base = self.nextSearchBaseLocation;
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_xvim.ignoreCase == TRUE) {
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
    if (found.location == NSNotFound && _xvim.wrapScan == TRUE) {
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
    NSTextView* srcView = [_xvim sourceView];
    NSUInteger search_base = self.nextSearchBaseLocation;
    search_base = [srcView selectedRange].location;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
    if (_xvim.ignoreCase == TRUE) {
        r_opts |= NSRegularExpressionCaseInsensitive;
    }
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:self.lastSearchString
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [_xvim statusMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchString] ringBell:TRUE];
        return;
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
    if (found.location == NSNotFound && _xvim.wrapScan == TRUE) {
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

@end
