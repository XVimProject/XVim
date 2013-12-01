//
//  NSCharacterSet+XVimAdditions.h
//  XVim
//
//  Created by John AppleSeed on 25/11/13.
//
//

#import <Foundation/Foundation.h>

@interface NSCharacterSet (XVimAdditions)

+ (NSCharacterSet *)xvim_octDigitsCharacterSet;
+ (NSCharacterSet *)xvim_hexDigitsCharacterSet;

@end
