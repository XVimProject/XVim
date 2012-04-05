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

@class XVim;

@interface XVimSearch: NSObject
@property BOOL lastSearchBackword;  // If the last search was '?' command this is true
@property (strong) NSString* lastSearchString;
@property (strong) NSString* lastReplacementString;
@property NSUInteger nextSearchBaseLocation;
@property NSUInteger endOfReplacement;

- (id)initWithXVim:(XVim*)xvim;
- (NSRange)executeSearch:(NSString*)searchCmd;
- (NSRange)searchNext;
- (NSRange)searchPrev;
- (void) substitute:(NSString*)string from:(NSUInteger)from to:(NSUInteger)to;

@end
