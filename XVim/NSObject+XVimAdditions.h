//
//  NSObject+XVimAdditions.h
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

/**
 ### How swizzling is working and XVim uses it ###
 Swizzling interface here just replaces a method to another method.
 When you call xvim_swizzleClassMethod to replace "Foo" with "Bar"
 calling "Foo" will invoke Bar's implementation and vice varsa.
 
 In XVim the typical usage of the swizzling is to hook event dispatch to
 a specific class.
 To hook an event XVim prepares new category method and then replace it with
 the original one.
 
 For example, let's say we want to hook keyDown: method in NSTextView.
 
    [NSTextView xvim_swizzleInstanceMethod:@selector(keyDown:) with:@selector(xvim_keyDown:)];
 
 xvim_keyDown: is already defined as a category method and it has its implementation.
 Now after calling this correspondance between the methods and the implemntations are following.
 
 keyDown: method     -----> xvim_keyDown: implementation
 xvim_keyDown method -----> keyDown: implementation
 
 So when an event is dispatched to NSTextView after this "xvim_keyDown:"'s IMPLEMENTATION will be invoked.
 
 To call original keyDown:'s implementation in xvim_keyDown:'s implementation you call
    [self xvim_keyDown:xxx]
 This looks weird because this looks calling itself and invoke infinite loop.
 But acutually invoking xvim_keyDown: METHOD will invoke keyDonw: IMPLEMENTATION.
 
**/

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

