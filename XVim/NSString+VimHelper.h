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
BOOL isNewline(unichar ch);
BOOL isNonblank(unichar ch);
BOOL isKeyword(unichar ch);

@interface NSString (VimHelper)

/**
 * Convert Vim regex to ICU regex.
 * If some control options are specified in Vim regex it will be returned via "options" argument.
 * This method never initialize passed "options".
 * This means that if nothing is specified in the Vim regex, "options" stays unchanged.
 **/
- (NSString*)convertToICURegex:(NSRegularExpressionOptions*)options;

- (NSMutableString *)newMutableSubstringWithRange:(NSRange)range;

+ (NSString *)stringMadeOfSpaces:(NSUInteger)count;

@end

@interface NSMutableString (VimHelper)
+ (NSMutableString *)mutableStringMadeOfSpaces:(NSUInteger)count;
- (void)appendCharacters:(const unichar *)chars length:(NSUInteger)length;
@end
