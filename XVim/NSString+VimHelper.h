//
//  NSString+VimHelper.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
BOOL isDigit(unichar ch);
BOOL isAlpha(unichar ch);
BOOL isDelimeter(unichar ch);
BOOL isWhitespace(unichar ch);
BOOL isNonAscii(unichar ch);
BOOL isNewline(unichar ch);
BOOL isNonblank(unichar ch);
BOOL isKeyword(unichar ch);

@interface NSString (VimHelper)
- (BOOL) isDigit:(NSUInteger)index;
- (BOOL) isAlpha:(NSUInteger)index;
- (BOOL) isDelimeter:(NSUInteger)index;
- (BOOL) isWhitespace:(NSUInteger)index;
- (BOOL) isNonAscii:(NSUInteger)index;
- (BOOL) isNewline:(NSUInteger)index;
- (BOOL) isNonblank:(NSUInteger)index;
- (BOOL) isKeyword:(NSUInteger)index;
@end
