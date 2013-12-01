//
//  NSObject+XVimAdditions.h
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <Foundation/Foundation.h>

@interface NSObject (XVimAdditions)

/** @brief swizzles class selector \a origSel with \a newSel.
 *
 * @param origSel  the name of the class method selector to swizzle
 * @param newSel   the name of the class method selector to use as a replacement
 */
+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel;
+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel imp:(IMP)imp;

/** @brief swizzles instance selector \a origSel with \a newSel.
 *
 * @param origSel  the name of the instance method selector to swizzle
 * @param newSel   the name of the instance method selector to use as a replacement
 *
 */
+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel;
+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel imp:(IMP)imp;

@end
