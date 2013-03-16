//
//  Hooker.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>

@interface Hooker : NSObject
/**
 * Hook method specified by "cls" and "mtd" by "cls2"-"mtd2.
 * All the calls to the "cls"-"mtd" will be redirected to "cls2", "mtd2"
 * When "mtd2" is called the "self" is "cls" object even its method in "cls2".
 * If you want to call original method in "mtd2" write [self mtd_];
 * Here "mtd_" is the name of method generated automatically to keep original method and genereted with following rule.
 *   Originam Method Name Rule:
 *       If it does not have any arguments the method name is created by appending "_" to original method name.
 *          - "length" method would be "length_"
 *          - "textStorage" method would be "textStorage_".
 *       If it has arguments the method name is created by inserting "_" before the first ":" of original method name.
 *          - "initWithFrame:" would be "initWithFrame_:"
 *          - "setSelectedRange:affinity:stillSelecting:" would be "setSelectedRange_:affinity:stillSelecting:"
 **/
+ (void) hookClass:(NSString*)cls method:(NSString*)mtd byClass:(NSString*)cls2 method:(NSString*)mtd2;
+ (void) unhookClass:(NSString*)cls method:(NSString*)mtd;

+ (void) hookMethod:(SEL)sel ofClass:(Class)cls withMethod:(Method)newMethod keepingOriginalWith:(SEL)selOriginal;

@end
