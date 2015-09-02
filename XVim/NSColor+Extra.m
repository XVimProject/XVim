//
//  NSColor+Extra.m
//  XVim
//
//  Created by Muronaka Hiroaki on 2015/08/30.
//
//

#import <Foundation/Foundation.h>
#import "NSColor+Extra.h"

@implementation NSColor (Extra)

+(NSColor*)colorWithRedInt:(NSInteger)redInt greenInt:(NSInteger)greenInt blueInt:(NSInteger)blueInt alphaInt:(NSInteger)alphaInt {
    
    CGFloat red = redInt / 255.0;
    CGFloat green = greenInt / 255.0;
    CGFloat blue = blueInt / 255.0;
    CGFloat alpha = alphaInt / 255.0;
    
    return [NSColor colorWithRed:red green:green blue:blue alpha:alpha];
}

+(NSColor*)colorWithString:(NSString*)str {
    
    str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSColor* result = nil;
    if( [str hasPrefix:@"#"] ) {
        result = [self colorWithHexString:str];
    } else {
        result = [self colorWithColorName:str];
    }
    return result;
}

+(NSColor*)colorWithHexString:(NSString *)hexStr {
    hexStr = [hexStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSScanner* scanner = [NSScanner scannerWithString:hexStr];
    
    if( [hexStr hasPrefix:@"#"] ) {
        scanner.scanLocation = 1;
    }
    
    UInt32 color = 0;
    [scanner scanHexInt:&color];
    
    UInt32 mask = 0x000000FF;
    NSInteger redInt = (color >> 16) & mask;
    NSInteger greenInt = (color >> 8) & mask;
    NSInteger blueInt = color & mask;
    
    return [self colorWithRedInt:redInt greenInt:greenInt blueInt:blueInt alphaInt:0x00FF];
}

+(NSColor*)colorWithColorName:(NSString *)colorName {
    
    colorName = [colorName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if( ![colorName hasSuffix:@"Color"] ) {
        colorName = [colorName stringByAppendingString:@"Color"];
    }
    
    NSColor* result = nil;
    SEL actionName = NSSelectorFromString(colorName);
    if( [self respondsToSelector:actionName] ) {
        result = (NSColor*)[NSColor performSelector:actionName];
    }
    return result;
}


@end
