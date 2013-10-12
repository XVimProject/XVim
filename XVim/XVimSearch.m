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

#pragma mark - XVimSearchMatch

@interface XVimSearchMatch : NSObject

@property (nonatomic, assign) NSRange range;
@property (nonatomic, assign) XVimPosition begin;
@property (nonatomic, assign) XVimPosition end;
@property (nonatomic, strong) NSTextCheckingResult *result;

@end

@implementation XVimSearchMatch

+ (instancetype)matchWithTextCheckingResult:(NSTextCheckingResult *)result inTextStorage:(NSTextStorage *)text
{
    XVimSearchMatch *match = [[self alloc] init];
    match.result = result;
    match.range = result.range;
    match.begin = XVimMakePosition([text lineNumber:result.range.location], [text columnNumber:result.range.location]);
    match.end = XVimMakePosition([text lineNumber:NSMaxRange(result.range)], [text columnNumber:NSMaxRange(result.range)]);
    return match;
}

@end

#pragma mark - XVimSearch

@implementation XVimSearch

- (id)init {
    if( self = [super init] ){
        _lastSearchDisplayString = @"";
        _lastReplacementString = @"";
        _lastSearchCase = XVimSearchCaseDefault;
        _lastSearchBackword = NO;
        _lastSearchCmd = @"";
        _lastSearchString = @"";
    }
    return self;
}

- (XVimMotion*)motionForRepeatSearch{
    return [self motionForSearch:self.lastSearchString forward:!self.lastSearchBackword];
}

- (XVimMotion*)motionForSearch:(NSString *)string forward:(BOOL)forward{
    XVimMotion* m = nil;
    if( forward ){
        XVim.instance.searcher.lastSearchBackword = NO;
        m = XVIM_MAKE_MOTION(MOTION_SEARCH_FORWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    }else{
        XVim.instance.searcher.lastSearchBackword = YES;
        m = XVIM_MAKE_MOTION(MOTION_SEARCH_BACKWARD, CHARACTERWISE_EXCLUSIVE, MOTION_OPTION_NONE, 1);
    }
    m.regex = string;
    
    // Find if it is case sensitive from 2 options(ignorecase/smartcase)
    BOOL ignorecase = XVim.instance.options.ignorecase;
    if (ignorecase && XVim.instance.options.smartcase){
        if( ![m.regex isEqualToString:[m.regex lowercaseString]] ){
            ignorecase = NO;
        }
    }
    
    // Case sensitiveness above can be overridden by Vim regex (\c,\C)
    NSRegularExpressionOptions options = ignorecase ? NSRegularExpressionCaseInsensitive:0;
    if( [XVim instance].options.vimregex ){
        m.regex = [m.regex convertToICURegex:&options];
    }
    // The last case sensitiveness is found at this point
    if( options & NSRegularExpressionCaseInsensitive ){
        m.option |= SEARCH_CASEINSENSITIVE;
    }
    
    if( [XVim instance].options.wrapscan ){
        m.option |= SEARCH_WRAP;
    }
    
    return m;
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
    
    /*
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
     */
    
    // in vi, if there's no search string. use the last one specified. like you do for 'n'
    if( [searchCmd length] > 1 ){
        self.lastSearchCmd = [searchCmd substringFromIndex:1];
    }
    NSRange r = [self searchNextFrom:from inWindow:window];
    /*
    if( [XVim instance].options.hlsearch ){
        [self highlightTextInView:window.sourceView];
    }
     */
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

- (NSRange)searchForwardFrom:(NSUInteger)from inWindow:(XVimWindow*)window{
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
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines | NSRegularExpressionUseUnicodeWordBoundaries;
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
                                         options:0
                                           range:NSMakeRange(search_base+1, [[srcView string] length] - search_base - 1)];
    }
    
    // if wrapscan is on, wrap to the top and search
    if (found.location == NSNotFound && options.wrapscan== TRUE) {
        found = [regex rangeOfFirstMatchInString:[srcView string] 
                                         options:0
                                           range:NSMakeRange(0, [[srcView string] length])];
        [window errorMessage:[NSString stringWithFormat:
                             @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:TRUE];
    }
    /*
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
     */
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
    
    NSRegularExpressionOptions r_opts = NSRegularExpressionAnchorsMatchLines;
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
                                       options:0
                                         range:NSMakeRange(0, [[srcView string] length])];
    
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
    // if wrapscan is on, search below base as well.
    if (found.location == NSNotFound && options.wrapscan == TRUE) {
        if ([matches count] > 0) {
            NSTextCheckingResult *match = ([matches objectAtIndex:[matches count]-1]);
            found = [match range];
            [window errorMessage:[NSString stringWithFormat: @"Search wrapped for '%@'",self.lastSearchDisplayString] ringBell:FALSE];
        }
    }
    
    /*
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
     */
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
	
    // TODO: must be moved to NSTextStorage+VimOperation
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
    if( forward ){
        found = [self executeSearch:searchString display:searchWord from:from<wordEnd?from:wordEnd inWindow:window];
    }
    else{
        found = [self executeSearch:searchString display:searchWord from:wordStart<from?wordStart:from inWindow:window];
    }

    /*
    if (found.location != NSNotFound &&
        ((!forward && begin.location != wordRange.location) ||
         (forward && searchStart != begin.location))){
			found = [self searchNextFrom:found.location inWindow:window];
    }
     */
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
    found = [regex rangeOfFirstMatchInString:[srcView string] options:0 range:NSMakeRange(from, [[srcView string] length] - from)];
    
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

#define arg_next(len)  (MIN(len, cur.length) > 0 ? [ex_arg substringWithRange:NSMakeRange(cur.location, MIN(len, cur.length))] : nil); cur = NSMakeRange(cur.location + MIN(len, cur.length), cur.length - MIN(len, cur.length));
#define arg_find(str)  ([ex_arg rangeOfString:str options:0 range:cur])
#define arg_seek(str)  arg_next(arg_find(str).location == NSNotFound ? cur.length : arg_find(str).location - cur.location)
#define str_contains(string, characterSet)  ([string rangeOfCharacterFromSet:characterSet].location != NSNotFound)

/*
 Perform a substitution from line eap->line1 to line eap->line2 using the
 command pointed to by eap->arg which should be of the form:

 /pattern/substitution/{flags}

 */
- (void)substitute:(NSString*)ex_arg from:(NSUInteger)fromLine to:(NSUInteger)toLine inWindow:(XVimWindow *)window
{
	XVimOptions *options = [[XVim instance] options];
   
    NSUInteger fromCol = 0;

    BOOL isGlobal = options.gdefault;
    BOOL isConfirm = NO;
    BOOL isIgnoreErrors = NO;
    BOOL isIgnoreCase = NO;

    NSString *delimiter;
    NSString *search;
    NSString *replace;

    NSRange cur = NSMakeRange(0, [ex_arg length]);

    // pattern

    delimiter = arg_next(1);

    if (str_contains(delimiter, [NSCharacterSet alphanumericCharacterSet])) {
        ERROR_LOG(@"Regular expressions can't be delimited by letters, got '%@'", delimiter);
        [window errorMessage:[NSString stringWithFormat:NSLocalizedString(@"Regular expressions can't be delimited by letters, got '%@'", nil), delimiter] ringBell:TRUE];
        return;
    }

    search = arg_seek(delimiter);
    arg_next(1);

    replace = arg_seek(delimiter);
    arg_next(1);

    if (search == nil) search = @""; 
    if (replace == nil) replace = @"";

    // flags

    NSString *flag = arg_next(1);

    while (flag) {
        if ([flag isEqualToString:@"g"]) isGlobal = !isGlobal;
        if ([flag isEqualToString:@"c"]) isConfirm = !isConfirm;
        if ([flag isEqualToString:@"e"]) isIgnoreErrors = !isIgnoreErrors;
        if ([flag isEqualToString:@"i"]) isIgnoreCase = YES;
        if ([flag isEqualToString:@"I"]) isIgnoreCase = NO;
        flag = arg_next(1);
    }

    // compile regex

    DEBUG_LOG(@"substitute: <delimiter = '%@', search = '%@', replace = '%@', isGlobal = %d, isConfirm = %d, isIgnoreErrors = %d, isIgnoreCase = %d, from = %d:%d, to = %d:%d>", delimiter, search, replace, isGlobal, isConfirm, isIgnoreErrors, isIgnoreCase, fromLine, fromCol, toLine, 0);

    self.lastSearchCmd = search;
    self.lastSearchDisplayString = search;
    self.lastReplacementString = replace;

    NSError *error;
    NSRegularExpression *regex = [self compileRegexWithSearch:search replace:replace ignoreCase:isIgnoreCase error:&error];

    if (!regex) {
        // test: "s/\xXX/x/"
        ERROR_LOG(@"Invalid regular expression '%@', %@", search, error);
        if (!isIgnoreErrors) {
            [window errorMessage:[NSString stringWithFormat:NSLocalizedString(@"Invalid expression, %@", nil), error.localizedFailureReason] ringBell:YES];
        }
        return;
    }
   
    // match each line

    NSTextStorage *text = window.sourceView.textStorage;

    NSUInteger idx = [text positionAtLineNumber:fromLine column:fromCol];
    NSUInteger lastIdx = 0;

    NSUInteger count = 0;

    [text beginEditing];

    /*
     * Search each line for matches that being in the line. Adjust parameters
     * for lines and chars added/removed as we go.
     */
    for (NSUInteger line = [text lineNumber:idx]; line <= toLine; line = [text lineNumber:idx])
    {
        /*
	     * Loop until nothing more to replace in this line.
	     * 1. Handle match with empty string.
	     * 2. If do_ask is set, ask for confirmation.
	     * 3. substitute the string.
	     * 4. if do_all is set, find next match
	     * 5. break if there isn't another match in this line
	     */
        for ( ; [text isValidCursorPosition:idx] ; )
        {
            DEBUG_LOG(@"  on <line = %d, idx = %d>: %@", line, idx, [text.xvim_string substringWithRange:NSMakeRange(idx, MIN([text endOfLine:idx] - idx, 50))]);

            NSRange range = NSMakeRange(idx, text.endOfFile - idx);
            NSTextCheckingResult *result = [regex firstMatchInString:text.xvim_string options:0 range:range];

            if (result == nil) {
                break; // nothing more on this line
            }

            XVimSearchMatch *match = [XVimSearchMatch matchWithTextCheckingResult:result inTextStorage:text];

            if (match.begin.line != line) {
                break; // match begins on next line
            }

            /*
             * 1. Match empty string does not count, except for first
             * match.  This reproduces the strange vi behaviour.
             * This also catches endless loops.
             */

            if (match.begin.column == match.end.column
                && match.begin.line == match.end.line
                && lastIdx
            ) {
                break;
            }

            lastIdx = idx;

            NSString *replacementString = [regex replacementStringForResult:match.result inString:window.sourceView.string offset:0 template:replace];

            /*
             * 2. If do_count is set only increase the counter.
             *    If `isConfirm` is set, ask for confirmation.
             */

            if (isConfirm) {
                DEBUG_LOG(@"replace with %s (y/n/a/q/l/^E/^Y)?", replacementString);
            }

            /*
             * 3. Substitute the string.
             *    We call [NSTextStorage replaceCharactersInRange:withString:]
             *    instead of [NSTextView insertText:replacementRange:] to avoid
             *    position errors with undo/redo.
             */

            if ([window.sourceView shouldChangeTextInRange:match.range replacementString:replacementString]) {
                [window.sourceView.textStorage replaceCharactersInRange:match.range withString:replacementString];
            }

            count++;                          // increase count
            idx  = match.range.location;      // advance cursor to end of match
            idx -= match.range.length;        // adjust for length differences
            idx += replacementString.length;

            /*
             * 4. If `isGlobal` is set, find next match.
             * Prevent endless loop with patterns that match empty
             * strings, e.g. :s/$/pat/g or :s/[a-z]* /(&)/g.
             * But ":s/\n/#/" is OK.
             */

            if (!isGlobal) {
                break;
            }
        }

        idx = [text nextLine:idx column:0 count:1 option:MOTION_OPTION_NONE];
       
        if ([text isLastCharacter:idx]) {
            break;
        }
       
        if (line + 1 != [text lineNumber:idx]) {
            // TODO: this gets stuck
            DEBUG_LOG(@"line count adjustment: before <nextLine = %d, toLine = %d>, adjusted <nextLine = %d, toLine = %d>, <diff = %+d>", line + 1, toLine, [text lineNumber:idx], toLine + ([text lineNumber:idx] - line), ([text lineNumber:idx] - line));
            toLine += [text lineNumber:idx] - line;
        }
    }

    [text endEditing];

    DEBUG_LOG(@"%lu substitutions", count);
    [window statusMessage:[NSString stringWithFormat:NSLocalizedString(@"%lu substitutions", @"{replacement count} substitutions"), count]];
}

- (NSRegularExpression *)compileRegexWithSearch:(NSString *)search replace:(NSString *)replace ignoreCase:(BOOL)ignoreCase error:(NSError **)error
{
    NSRegularExpression *regex;
    NSRegularExpressionOptions opts = 0;

    opts |= NSRegularExpressionAnchorsMatchLines;
    opts |= NSRegularExpressionUseUnicodeWordBoundaries;

    if (ignoreCase) {
        opts |= NSRegularExpressionCaseInsensitive;
    }

    *error = nil;
    regex = [NSRegularExpression regularExpressionWithPattern:search options:opts error:error];

    if (*error) {
        return nil;
    }

    return regex;
}

@end
