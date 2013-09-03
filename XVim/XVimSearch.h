//
//  XVimSearch.h
//  XVim
//
//  Created by Shuichiro Suzuki on 3/26/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

// Handles /,? searches
// This may be also used in range specifier in the future.

#import <Foundation/Foundation.h>

@class XVimWindow;
@class XVimMotion;

typedef enum {
    XVimSearchCaseDefault,
    XVimSearchCaseSensitive,
    XVimSearchCaseInsensitive
} XVimSearchCase;

@interface XVimSearch: NSObject
@property BOOL lastSearchBackword;  // If the last search was '?' command this is true
@property XVimSearchCase lastSearchCase;  // If the last search had "\c" or "\C"
@property (strong) NSString* lastSearchCmd;
@property (strong) NSString* lastSearchString;
@property (strong) NSString* lastSearchDisplayString;
@property (strong) NSString* lastReplacementString;
@property BOOL matchStart;
@property BOOL matchEnd;

- (BOOL)isCaseInsensitive;
// - (NSRange)executeSearch:(NSString*)searchCmd display:(NSString*)displayString from:(NSUInteger)from inWindow:(XVimWindow*)window;
// - (NSRange)searchNextFrom:(NSUInteger)from inWindow:(XVimWindow*)window;
// - (NSRange)searchPrevFrom:(NSUInteger)from inWindow:(XVimWindow*)window;
// - (NSRange)searchCurrentWordFrom:(NSUInteger)from forward:(BOOL)forward matchWholeWord:(BOOL)wholeWord inWindow:(XVimWindow*)window;

// Tries to select the passed range. 
// If range.location == NSNotFound, an error is added to the command line
// Returns whether range.location is valid
// - (BOOL)selectSearchResult:(NSRange)r inWindow:(XVimWindow*)window;

- (XVimMotion*)motionForRepeatSearch;
- (XVimMotion*)motionForSearch:(NSString*)string forward:(BOOL)forward;
- (void)substitute:(NSString*)searchCmd from:(NSUInteger)from to:(NSUInteger)to inWindow:(XVimWindow*)window;

@end
