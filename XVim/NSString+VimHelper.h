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

/**
 * Convert Vim regex to ICU regex.
 * If some control options are specified in Vim regex it will be returned via "options" argument.
 * This method never initialize passed "options".
 * This means that if nothing is specified in the Vim regex, "options" stays unchanged.
 **/
- (NSString*)convertToICURegex:(NSRegularExpressionOptions*)options;
@end
