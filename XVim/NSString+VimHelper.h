//
//  NSString+VimHelper.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/10/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

BOOL isDigit(unichar ch);
BOOL isOctDigit(unichar ch);
BOOL isHexDigit(unichar ch);
BOOL isAlpha(unichar ch);
BOOL isDelimeter(unichar ch);
BOOL isWhitespace(unichar ch);
BOOL isNewline(unichar ch);
BOOL isNonblank(unichar ch);
BOOL isWhiteSpaceOrNewline(unichar ch);
BOOL isKeyword(unichar ch);

@interface NSString (VimHelper)
- (BOOL) isDigit:(NSUInteger)index;
- (BOOL) isOctDigit:(NSUInteger)index;
- (BOOL) isHexDigit:(NSUInteger)index;
- (BOOL) isAlpha:(NSUInteger)index;
- (BOOL) isDelimeter:(NSUInteger)index;
- (BOOL) isNewline:(NSUInteger)index;
- (BOOL) isKeyword:(NSUInteger)index;

/**
 * Convert Vim regex to ICU regex.
 * If some control options are specified in Vim regex it will be returned via "options" argument.
 * This method never initialize passed "options".
 * This means that if nothing is specified in the Vim regex, "options" stays unchanged.
 **/
- (NSString*)convertToICURegex:(NSRegularExpressionOptions*)options;

+ (NSString *)stringMadeOfSpaces:(NSUInteger)count;
@end

@interface NSMutableString (VimHelper)
+ (NSMutableString *)mutableStringMadeOfSpaces:(NSUInteger)count;
@end
