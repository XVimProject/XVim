//
//  Utils.m
//  XVim
//
//  Created by Suzuki Shuichiro on 2/16/13.
//
//

#import "Utils.h"

@implementation NSColor(StringExpression)

+ (NSColor*)colorWithString:(NSString *)stringExpr{
    NSAssert(nil != stringExpr, @"must not be nil");  
    if( [stringExpr hasPrefix:@"#"] ){
        // expect #rrggbb format
        if( stringExpr.length != 7 ){
            return nil;
        }
        unsigned int r, g, b;
        [[NSScanner scannerWithString:[stringExpr substringWithRange:NSMakeRange(1,2)]] scanHexInt:&r];
        [[NSScanner scannerWithString:[stringExpr substringWithRange:NSMakeRange(3,2)]] scanHexInt:&g];
        [[NSScanner scannerWithString:[stringExpr substringWithRange:NSMakeRange(5,2)]] scanHexInt:&b];
        return [NSColor colorWithSRGBRed:(float)r/255.0 green:(float)g/255.0 blue:(float)b/255.0 alpha:1.0];
    }else{
        // expect color name
        NSString* cname = [stringExpr stringByAppendingString:@"Color"]; // Something like 'yellowColor'
        SEL sel = NSSelectorFromString(cname);
        if( [self respondsToSelector:sel]){
            return [self performSelector:sel];
        }
    }
    return nil;
}

@end

@implementation Utils

@end
