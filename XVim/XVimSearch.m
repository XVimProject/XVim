//
//  XVimSearch.m
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimSearch.h"
#import "NSTextView+VimOperation.h"
#import "NSString+VimHelper.h"
#import "XVimWindow.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "Logger.h"
#import "XVimUtil.h"
#import "IDEKit.h"

@implementation XVimSearch

- (id)init {
    if( self = [super init] ){
        _lastSearchDisplayString = @"";
        _lastReplacementString = @"";
        _lastSearchCase = XVimSearchCaseDefault;
        _lastSearchBackword = NO;
        _lastSearchCmd = @"";
        [[XVim instance].options addObserver:self forKeyPath:@"hlsearch" options:NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viewDidChangeText:) name:NSTextDidChangeNotification object:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context{
    if( [keyPath isEqualToString:@"hlsearch"]) {
        if( [XVim instance].options.hlsearch ){
            [self highlightTextInView:XVimLastActiveSourceView()];
        }else{
            [self clearHighlightTextInView:XVimLastActiveSourceView()];
        }
    }
    
}

- (void)viewDidChangeText:(NSNotification*)notification{
    if( [NSStringFromClass([notification.object class]) isEqualToString:@"DVTSourceTextView"] ){
        [self updateSearchStateInView:notification.object];
    }
}

- (void)clearHighlightTextInView:(NSTextView*)view{
    NSString* string = view.string;
    NSTextStorage* storage = [view textStorage];
    [storage addAttribute:NSBackgroundColorAttributeName value:[NSColor clearColor] range:NSMakeRange(0, string.length)];
    [storage endEditing];
    [view setNeedsDisplay:YES];
    
}

// Thanks to  http://lists.apple.com/archives/cocoa-dev/2005/Jun/msg01909.html
- (NSRange)visibleRange:(NSTextView *)tv{
    NSScrollView *sv = [tv enclosingScrollView];
    if(!sv) return NSMakeRange(0,0);
    NSLayoutManager *lm = [tv layoutManager];
    NSRect visRect = [tv visibleRect];
    
    NSPoint tco = [tv textContainerOrigin];
    visRect.origin.x -= tco.x;
    visRect.origin.y -= tco.y;
    
    NSRange glyphRange = [lm glyphRangeForBoundingRect:visRect inTextContainer:[tv textContainer]];
    NSRange charRange = [lm characterRangeForGlyphRange:glyphRange actualGlyphRange:nil];
    return charRange;
}

- (void)highlightTextInView:(NSTextView*)view{
    if( nil == view ){
        return;
    }
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnicodeWordBoundaries;
	if ([self isCaseInsensitive]) {
		r_opts |= NSRegularExpressionCaseInsensitive;
	}

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.lastSearchCmd options:r_opts error:&error];
    NSString* string = view.string;
    NSTextStorage* storage = [view textStorage];
    // Find all the maches
    NSArray*  matches = [regex matchesInString:string options:r_opts range:NSMakeRange(0, string.length)];
    // Add attributes to the each range
    
    
    // There is 2 ways to add attributes
    // One is to add attributes to NSAttributedString(NSTextStorage)
    // One is to add attributes to NSLayoutManager by addTempraryAttributes
    // Later is faster so I use it here.
    
    // Clear current highlight.
    [view.layoutManager removeTemporaryAttribute:NSBackgroundColorAttributeName forCharacterRange:NSMakeRange(0, storage.length)];
    // Add yellow highlight
    for( NSTextCheckingResult* result in matches ){
        [view.layoutManager addTemporaryAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] forCharacterRange:result.range];
    }
    [view setNeedsDisplayInRect:[view visibleRect] avoidAdditionalLayout:YES];
}

- (void)updateSearchStateInView:(NSTextView*)view{
    if( [XVim instance].options.hlsearch ){
        [self highlightTextInView:view];
    }
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
    
    if([searchCmd  rangeOfString:@"\\<"].location != NSNotFound){
        self.matchStart = TRUE;
    }else {
        self.matchStart = FALSE;
    }
    if([searchCmd rangeOfString:@"\\>"].location != NSNotFound){
        self.matchEnd = TRUE;
    }else {
        self.matchEnd = FALSE;
    }
    // In vim \< matches the start of a word and \> matches the end of vims definition of a word.
    // Using NSRegularExpression with NSRegularExpressionUseUnicodeWordBoundaries
    // \b matches word boundaries.
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\<" withString:@"(:|\\.|\\b)"];
    searchCmd = [searchCmd stringByReplacingOccurrencesOfString:@"\\>" withString:@"(:|\\.|\\b)"];
    
    // in vi, if there's no search string. use the last one specified. like you do for 'n'
    if( [searchCmd length] > 1 ){
        self.lastSearchCmd = [searchCmd substringFromIndex:1];
    }
    NSRange r = [self searchNextFrom:from inWindow:window];
    if( [XVim instance].options.hlsearch ){
        [self highlightTextInView:window.sourceView];
    }
    return r;
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
	

    NSRange found = {NSNotFound, 0};
#ifdef __MAC_10_7
    XVimOptions *options = [[XVim instance] options];
    
    NSTextView* srcView = [window sourceView];
    NSUInteger search_base = from;
    
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
        [window errorMessage:[NSString stringWithFormat:
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
        [window errorMessage:[NSString stringWithFormat:
                             @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:TRUE];
    }
    if((self.matchStart || self.matchEnd) && found.location != NSNotFound){
        //figure out the true start and end of the word because the NSRegularExpression engine treats
        // . and : characters are part of the larger word and will not match on a \b regular expression search. 
        unichar firstChar = [[srcView string] characterAtIndex:found.location];
        unichar lastChar = [[srcView string] characterAtIndex:(found.location + found.length - 1)];
        if (self.matchStart && (firstChar == '.' || firstChar == ':')) {
            found.location++;
            found.length--;
        }
        if(self.matchEnd && (lastChar == '.' || lastChar == ':')){
            found.length--;
        }
    }
#endif
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

    NSRange found = {NSNotFound, 0};
#ifdef __MAC_10_7    
	XVimOptions *options = [[XVim instance] options];
    NSTextView* srcView = [window sourceView];
    NSUInteger search_base = from;
    
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
        [window errorMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchDisplayString] ringBell:TRUE];
        return NSMakeRange(NSNotFound,0);
    }
    
    NSArray*  matches = [regex matchesInString:[srcView string]
                                       options:r_opts
                                         range:NSMakeRange(0, [[srcView string] length]-1)];
    
    // search above base
    if (search_base > 0) {
        for (NSTextCheckingResult *match in matches) { // get last match in area before search_base
            NSRange tmp = [match range];
            // handle the case where the search string includes a . or : in the first location
            if (tmp.location >= search_base || (self.matchStart && tmp.location+1 >= search_base))
                break;
            found = tmp;
        }
    }
    // if wrapscan is on, search below base as well
    if (found.location == NSNotFound && options.wrapscan == TRUE) {
        if ([matches count] > 0) {
            NSTextCheckingResult *match = ([matches objectAtIndex:[matches count]-1]);
            found = [match range];
            [window errorMessage:[NSString stringWithFormat: @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:FALSE];
        }
    }
    
    if((self.matchStart || self.matchEnd) && found.location != NSNotFound){
        //figure out the true start and end of the word because the NSRegularExpression engine treats
        // . and : characters are part of the larger word and will not match on a \b regular expression search. 
        unichar firstChar = [[srcView string] characterAtIndex:found.location];
        unichar lastChar = [[srcView string] characterAtIndex:(found.location + found.length - 1)];
        if (self.matchStart && (firstChar == '.' || firstChar == ':')) {
            found.location++;
            found.length--;
        }
        if(self.matchEnd && (lastChar == '.' || lastChar == ':')){
            found.length--;
        }
    }    
#endif
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
    NSRange found = {NSNotFound,0};
#ifdef __MAC_10_7
    NSTextView *view = [window sourceView];

    NSRange begin = [view selectedRange];
    NSString *string = [view string];
    NSUInteger searchStart = NSNotFound;
    NSUInteger firstNonblank = NSNotFound;
	
	for (NSUInteger i = begin.location; ![view.textStorage isEOF:i]; ++i)
	{
        unichar curChar = [string characterAtIndex:i];
        if (isNewline(curChar)){
            break;
        }

        if (isKeyword(curChar)){
			searchStart = i;
            break;
        }

        if (isNonblank(curChar) && firstNonblank == NSNotFound){
            firstNonblank = i;
        }

        ++i;
    }

    if (searchStart == NSNotFound){
        searchStart = firstNonblank;
    }

    if (searchStart == NSNotFound){
        return NSMakeRange(NSNotFound, 0);
    }

    XVimMotionInfo info;
    NSUInteger wordStart = searchStart;
    if (wordStart > 0){
        unichar curChar = [string characterAtIndex:wordStart];
        unichar lastChar = [string characterAtIndex:wordStart-1];
        if ((isKeyword(curChar) && isKeyword(lastChar)) ||
            (!isKeyword(curChar) && isNonblank(curChar) && !isKeyword(lastChar) && isNonblank(lastChar))){
            wordStart = [view.textStorage wordsBackward:searchStart count:1 option:LEFT_RIGHT_NOWRAP];
        }
    }

    NSUInteger wordEnd = [view.textStorage wordsForward:wordStart count:1 option:LEFT_RIGHT_NOWRAP info:&info];
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
    found = [self executeSearch:searchString display:searchWord from:from inWindow:window];

    if (found.location != NSNotFound &&
        ((!forward && begin.location != wordRange.location) ||
         (forward && searchStart != begin.location))){
			found = [self searchNextFrom:found.location inWindow:window];
    }
#endif
    return found;
}

- (NSRange)replaceForwardFrom:(NSUInteger)from to:(NSUInteger)to inWindow:(XVimWindow*)window
{
    // We don't use [NSString rangeOfString] for searching, because it does not obey ^ or $ search anchoring
    // We use NSRegularExpression which does (if you tell it to)
    
    NSRange found = {NSNotFound, 0};
    
#ifdef __MAC_10_7    
    
    NSTextView* srcView = [window sourceView];
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines|NSRegularExpressionUseUnicodeWordBoundaries;
	if ([self isCaseInsensitive])
	{
		r_opts |= NSRegularExpressionCaseInsensitive;
	}
    
    NSError *error = NULL;
    TRACE_LOG(@"%@", self.lastReplacementString);
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:self.lastSearchCmd options:r_opts error:&error];
    
    if (error != nil) {
        [window errorMessage:[NSString stringWithFormat: @"Cannot compile regular expression '%@'",self.lastSearchDisplayString] ringBell:TRUE];
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
#endif    
    return found;
}

- (void)substitute:(NSString*)ex_command from:(NSUInteger)from to:(NSUInteger)to inWindow:(XVimWindow*)window
{
	XVimOptions *options = [[XVim instance] options];
    // Split the string into the various components
    NSString* replaced = @"";
    NSString* replacement = @"";
    unichar previous = 0;
    int component = 0;
    BOOL global = options.gdefault;
    BOOL confirmation = NO;
    if ([ex_command length] >= 3) {
        for(NSUInteger i=1;i<[ex_command length];++i) {
            unichar current = [ex_command characterAtIndex:i];
            if (current == '/' && previous != '\\') {
                component++;
            } else {
                if (component == 0) {
                    replaced = [NSString stringWithFormat:@"%@%C",replaced,current];
                } else if (component == 1) {
                    replacement = [NSString stringWithFormat:@"%@%C",replacement,current];
                } else {
                    if (current == 'g') {
                        global = !global;
                    } else if (current == 'c') {
                        confirmation = YES;
                    } else {
                        ERROR_LOG("Unknown replace option %C",current);
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
    NSUInteger replace_start_location = [window.sourceView.textStorage positionAtLineNumber:from column:0];
    if( NSNotFound == replace_start_location){
        return;
    }
    
    // Find the position to end the searching
    NSUInteger endOfReplacement = [window.sourceView.textStorage positionAtLineNumber:to+1 column:0]; // Next line of the end of range.
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
    [window errorMessage:[NSString stringWithFormat: @"Number of occurrences replaced %d",numReplacements] ringBell:TRUE];

}

- (BOOL)selectSearchResult:(NSRange)found inWindow:(XVimWindow*)window{
	BOOL valid = found.location != NSNotFound;
	
	// Move cursor and show the found string
    if(valid) {
		NSTextView* srcView = [window sourceView];
        [srcView setSelectedRange:NSMakeRange(found.location, 0)];
		[srcView xvim_scrollTo:[srcView insertionPoint]];
        [srcView showFindIndicatorForRange:found];
    }else{
        [window errorMessage:[NSString stringWithFormat: @"Cannot find '%@'", self.lastSearchDisplayString] ringBell:TRUE];
    }
	
	return valid;
}

@end
