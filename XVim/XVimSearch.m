//
//  XVimSearch.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearch.h"
#import "XVimSourceView.h"
#import "XVimSourceView+Vim.h"
#import "NSString+VimHelper.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "Logger.h"

@implementation XVimSearch
@synthesize lastSearchCase = _lastSearchCase;
@synthesize lastSearchBackword = _lastSearchBackword;
@synthesize lastSearchCmd = _lastSearchCmd;
@synthesize lastSearchDisplayString = _lastSearchDisplayString;
@synthesize lastReplacementString = _lastReplacementString;

- (id)init
{
    if( self = [super init] ){
        _lastSearchDisplayString = @"";
        _lastReplacementString = @"";
        _lastSearchCase = XVimSearchCaseDefault;
        _lastSearchBackword = NO;
    }
    return self;
}

- (NSRange)executeSearch:(NSString*)searchCmd display:(NSString*)displayString from:(NSUInteger)from inWindow:(XVimWindow*)window
{
    unichar first = [searchCmd characterAtIndex:0];
    if( first == '?' ){
        self.lastSearchBackword = YES;
    }else if( first == '/' ){
        self.lastSearchBackword = NO;
    }else{
        NSAssert(NO, @"first letter of search command must be ? or /");
    }
    
    // Store off the original search string into the lastSearchString
    self.lastSearchDisplayString = displayString;
    
    // In vim \c specifies a case insensitive search and \C specifies case sensitive
    // If there are any \c then it overrides any \C that may be in the search string
    if ([searchCmd rangeOfString:@"\\c"].location != NSNotFound){
        self.lastSearchCase = XVimSearchCaseInsensitive;
    }else if ([searchCmd rangeOfString:@"\\C"].location != NSNotFound){
        self.lastSearchCase = XVimSearchCaseSensitive;
    }else{
        self.lastSearchCase = XVimSearchCaseDefault;
    }
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\c" withString:@""];
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\C" withString:@""];
    
    // In vim \< matches the start of a word and \> matches the end of a word.
    // Using NSRegularExpression with NSRegularExpressionUseUnicodeWordBoundaries
    // \b matches word boundaries, but for some reason it does not properly handle : or .
    // so add it to the search. This is not ideal but it mostly works. Please see
    // the NSRegularExpression documentation for more info on this regular exrpression.
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\<" withString:@"(:|\\.|\\b)"];
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\>" withString:@"(:|\\.|\\b)"];
    
    // in vi, if there's no search string. use the last one specified. like you do for 'n'
    if( [searchCmd length] > 1 ){
        self.lastSearchCmd = [searchCmd substringFromIndex:1];
    }
    return [self searchNextFrom:from inWindow:window];
}

- (BOOL)isCaseInsensitive
{
	if (self.lastSearchCase == XVimSearchCaseInsensitive) { return YES; }
	if (self.lastSearchCase == XVimSearchCaseSensitive) { return NO; }
	
	XVimOptions *options = [[XVim instance] options];
	BOOL ignorecase = options.ignorecase;
	if (ignorecase && options.smartcase)
	{
		ignorecase = [self.lastSearchCmd isEqualToString:[self.lastSearchCmd lowercaseString]];
	}
	return ignorecase;
}

- (NSRange)searchForwardFrom:(NSUInteger)from inWindow:(XVimWindow*)window 
{
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
	if (!self.lastSearchCmd) {
		return NSMakeRange(NSNotFound,0);
	}
	
	XVimOptions *options = [[XVim instance] options];

    XVimSourceView* srcView = [window sourceView];
    NSUInteger search_base = from;
    NSRange found = {NSNotFound, 0};

    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnicodeWordBoundaries;
	if ([self isCaseInsensitive])
	{
		r_opts |= NSRegularExpressionCaseInsensitive;
	}

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:self.lastSearchCmd
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [[XVim instance] errorMessage:[NSString stringWithFormat:
                             @"Cannot compile regular expression '%@'",self.lastSearchDisplayString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    // search text beyond the search_base
    if( [[srcView string] length]-1 > search_base){
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:r_opts
                                           range:NSMakeRange(search_base+1, [[srcView string] length] - search_base - 1)];
    }
    
    // if wrapscan is on, wrap to the top and search
    if (found.location == NSNotFound && options.wrapscan== TRUE) {
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:r_opts
                                           range:NSMakeRange(0, [[srcView string] length])];
        [[XVim instance] errorMessage:[NSString stringWithFormat:
                             @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:TRUE];
    }
    
    return found;
}


- (NSRange)searchBackwardFrom:(NSUInteger)from inWindow:(XVimWindow*)window
{
	if (!self.lastSearchCmd) {
		return NSMakeRange(NSNotFound,0);
	}
	
    // opts = (NSBackwardsSearch | NSRegularExpressionSearch) is not supported by [NSString rangeOfString:opts]
    // What we do instead is a search for all occurences and then
    // use the range of the last match. Not very efficient, but i don't think
    // optimization is warranted until slowness is experienced at the user level.
	XVimOptions *options = [[XVim instance] options];
	
    XVimSourceView* srcView = [window sourceView];
    NSUInteger search_base = from;
    NSRange found = {NSNotFound, 0};
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnicodeWordBoundaries;
	if ([self isCaseInsensitive])
	{
		r_opts |= NSRegularExpressionCaseInsensitive;
	}
    
    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression 
                                  regularExpressionWithPattern:self.lastSearchCmd
                                  options:r_opts
                                  error:&error];
    
    if (error != nil) {
        [[XVim instance] errorMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchDisplayString] ringBell:TRUE];
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
    if (found.location == NSNotFound && options.wrapscan == TRUE) {
        if ([matches count] > 0) {
            NSTextCheckingResult *match = ([matches objectAtIndex:[matches count]-1]);
            found = [match range];
            [[XVim instance] errorMessage:[NSString stringWithFormat: @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:FALSE];
        }
    }
	 
    return found;
}

- (NSRange)searchNextFrom:(NSUInteger)from inWindow:(XVimWindow*)window
{
    if( self.lastSearchBackword ){
        return [self searchBackwardFrom:from inWindow:window];
    }else{
        return [self searchForwardFrom:from inWindow:window];
    }
}

- (NSRange)searchPrevFrom:(NSUInteger)from inWindow:(XVimWindow*)window
{
    if( self.lastSearchBackword ){
        return [self searchForwardFrom:from inWindow:window];
    }else{
        return [self searchBackwardFrom:from inWindow:window];
    }
}

- (NSRange)searchCurrentWordFrom:(NSUInteger)from forward:(BOOL)forward matchWholeWord:(BOOL)wholeWord inWindow:(XVimWindow*)window
{
    XVimSourceView *view = [window sourceView];

    NSRange begin = [view selectedRange];
    NSString *string = [view string];
    NSUInteger searchStart = NSNotFound;
    NSUInteger firstNonBlank = NSNotFound;
	
	for (NSUInteger i = begin.location; ![view isEOF:i]; ++i)
	{
        unichar curChar = [string characterAtIndex:i];
        if (isNewLine(curChar)){
            break;
        }

        if (isKeyword(curChar)){
			searchStart = i;
            break;
        }

        if (isNonBlank(curChar) && firstNonBlank == NSNotFound){
            firstNonBlank = i;
        }

        ++i;
    }

    if (searchStart == NSNotFound){
        searchStart = firstNonBlank;
    }

    if (searchStart == NSNotFound){
        return NSMakeRange(NSNotFound, 0);
    }

    XVimWordInfo info;
    NSUInteger wordStart = searchStart;
    if (wordStart > 0){
        unichar curChar = [string characterAtIndex:wordStart];
        unichar lastChar = [string characterAtIndex:wordStart-1];
        if ((isKeyword(curChar) && isKeyword(lastChar)) ||
            (!isKeyword(curChar) && isNonBlank(curChar) && !isKeyword(lastChar) && isNonBlank(lastChar))){
            wordStart = [view wordsBackward:searchStart count:1 option:LEFT_RIGHT_NOWRAP];
        }
    }

    NSUInteger wordEnd = [view wordsForward:wordStart count:1 option:LEFT_RIGHT_NOWRAP info:&info];
    if (info.lastEndOfWord != NSNotFound){
        wordEnd = info.lastEndOfWord;
    }

    // Search for the word
    NSRange wordRange = NSMakeRange(wordStart, wordEnd - wordStart + 1);
    NSString *searchWord = [[view string] substringWithRange:wordRange];
    NSString *escapedSearchWord = [NSRegularExpression escapedPatternForString:searchWord];

    if (wholeWord){
        escapedSearchWord = [@"\\<" stringByAppendingString:[escapedSearchWord stringByAppendingString:@"\\>"]];
    }

    NSString *searchString = [(forward ? @"/" : @"?") stringByAppendingString:escapedSearchWord];
    NSRange found = [self executeSearch:searchString display:searchWord from:from inWindow:window];

    if (found.location != NSNotFound &&
        ((!forward && begin.location != wordRange.location) ||
         (forward && searchStart != begin.location))){
			found = [self searchNextFrom:found.location inWindow:window];
    }

    return found;
}

- (NSRange)replaceForwardFrom:(NSUInteger)from to:(NSUInteger)to inWindow:(XVimWindow*)window
{
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    XVimSourceView* srcView = [window sourceView];
    NSRange found = {NSNotFound, 0};
    
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnicodeWordBoundaries;
	if ([self isCaseInsensitive])
	{
		r_opts |= NSRegularExpressionCaseInsensitive;
	}
    
    NSError *error = NULL;
    TRACE_LOG(@"%@", self.lastReplacementString);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.lastSearchCmd options:r_opts error:&error];
    
    if (error != nil) {
        [[XVim instance] errorMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchDisplayString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    // search text beyond the search_base
    found = [regex rangeOfFirstMatchInString:[srcView string] options:r_opts range:NSMakeRange(from, [[srcView string] length] - from)];
    
    if( found.location >= to) {
        return NSMakeRange(NSNotFound, 0);
    }
    if( found.location != NSNotFound){
        // Replace the text
        // The following method is undoable
        [srcView insertText:self.lastReplacementString replacementRange:found];
    }
    
    return found;
}

- (void)substitute:(NSString*)ex_command from:(NSUInteger)from to:(NSUInteger)to inWindow:(XVimWindow*)window
{
	XVimOptions *options = [[XVim instance] options];
    // Split the string into the various components
    NSString* replaced = @"";
    NSString* replacement = @"";
    char previous = 0;
    int component = 0;
    BOOL global = options.gdefault;
    BOOL confirmation = NO;
    if ([ex_command length] >= 3) {
        for(NSUInteger i=1;i<[ex_command length];++i) {
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
                        global = !global;
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
    self.lastSearchCmd = replaced;
    self.lastSearchDisplayString = replaced;
    self.lastReplacementString = replacement;
    
    // Find the position to start searching
    NSUInteger replace_start_location = [[window sourceView] positionAtLineNumber:from column:0];
    if( NSNotFound == replace_start_location){
        return;
    }
    
    // Find the position to end the searching
    NSUInteger endOfReplacement = [[window sourceView] positionAtLineNumber:to+1 column:0]; // Next line of the end of range.
    if( NSNotFound == endOfReplacement ){
        endOfReplacement = [[[window sourceView] string] length];
    }
    // This is lazy implementation.
    // When text is substituted the end location may be smaller or greater than original end position.
    // I'll implement correct version later.
    
    // Replace all the occurrences
    int numReplacements = 0;
    NSRange found;
    do {
        found = [self replaceForwardFrom:replace_start_location to:endOfReplacement inWindow:window];
        if (found.location != NSNotFound) {
            numReplacements++;
        }
		replace_start_location = found.location + [replacement length];
		endOfReplacement = endOfReplacement + [replacement length] - found.length;
    } while(found.location != NSNotFound && global && replace_start_location < endOfReplacement);
    [[XVim instance] errorMessage:[NSString stringWithFormat: @"Number of occurrences replaced %d",numReplacements] ringBell:TRUE];
    
}

- (BOOL)selectSearchResult:(NSRange)found inWindow:(XVimWindow*)window
{
	BOOL valid = found.location != NSNotFound;
	
	// Move cursor and show the found string
    if(valid) {
		XVimSourceView* srcView = [window sourceView];
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
		[srcView scrollTo:[window insertionPoint]];
        [srcView showFindIndicatorForRange:found];
    }else{
        [[XVim instance] errorMessage:[NSString stringWithFormat: @"Cannot find '%@'", self.lastSearchDisplayString] ringBell:TRUE];
    }
	
	return valid;
}

@end
