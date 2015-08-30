//
//  NSColor+Extra.h
//  XVim
//
//  Created by Muronaka Hiroaki on 2015/08/30.
//
//

#import <Cocoa/Cocoa.h>

@interface NSColor (Extra)

+(NSColor*)colorWithRedInt:(NSInteger)red greenInt:(NSInteger)green blueInt:(NSInteger)blue alphaInt:(NSInteger)alpha;
+(NSColor*)colorWithString:(NSString*)str;
+(NSColor*)colorWithHexString:(NSString*)hexStr;
+(NSColor*)colorWithColorName:(NSString*)colorName;

@end
