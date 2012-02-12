//
//  Hooker.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import <objc/runtime.h>


@interface Hooker : NSObject
+ (void) hookMethod:(SEL)sel ofClass:(Class)cls withMethod:(Method)newMethod keepingOriginalWith:(SEL)selOriginal;
@end
