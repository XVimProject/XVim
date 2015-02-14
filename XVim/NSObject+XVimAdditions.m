//
//  NSObject+XVimAdditions.m
//  XVim
//
//  Created by John AppleSeed on 21/11/13.
//
//

#import <objc/runtime.h>
#import "NSObject+XVimAdditions.h"

@implementation NSObject (XVimAdditions)

+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel
{
    Method origMethod = class_getClassMethod(self, origSel);
    Method newMethod  = class_getClassMethod(self, newSel);
    Class class = object_getClass(self);

    NSAssert(origMethod, @"+[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(origSel));
    NSAssert(newMethod,  @"+[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(newSel));

    if (class_addMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(class, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
    } else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

+ (void)xvim_swizzleClassMethod:(SEL)origSel with:(SEL)newSel imp:(IMP)imp
{
    Method origMethod = class_getClassMethod(self, origSel);
    Method newMethod  = class_getClassMethod(self, newSel);

    NSAssert(origMethod, @"+[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(origSel));
    NSAssert(!newMethod, @"+[%@ %@] exists", NSStringFromClass(self), NSStringFromSelector(newSel));

    class_addMethod(self, newSel, imp, method_getTypeEncoding(origMethod));
    [self xvim_swizzleClassMethod:origSel with:newSel];
}

+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel
{
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method newMethod  = class_getInstanceMethod(self, newSel);

    NSAssert(newMethod,  @"-[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(newSel));

    if (class_addMethod(self, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod))) {
        class_replaceMethod(self, origSel, method_getImplementation(newMethod), method_getTypeEncoding(newMethod));
        class_replaceMethod(self, newSel, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    } else {
        method_exchangeImplementations(newMethod, origMethod);
    }
}

+ (void)xvim_swizzleInstanceMethod:(SEL)origSel with:(SEL)newSel imp:(IMP)imp
{
    Method origMethod = class_getInstanceMethod(self, origSel);
    Method newMethod  = class_getInstanceMethod(self, newSel);

    NSAssert(origMethod, @"-[%@ %@] doesn't exist", NSStringFromClass(self), NSStringFromSelector(origSel));
    NSAssert(!newMethod, @"-[%@ %@] exists", NSStringFromClass(self), NSStringFromSelector(newSel));

    class_addMethod(self, newSel, imp, method_getTypeEncoding(origMethod));
    [self xvim_swizzleInstanceMethod:origSel with:newSel];
}

@end

