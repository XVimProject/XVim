//
//  Hooker.m
//  XVim
//
//  Created by Shuichiro Suzuki on 2/3/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "Hooker.h"

@implementation Hooker

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
    }
    
    return self;
}

// clsに渡されたクラスのselセレクタを呼び出したときに実行されるメソッドをフックし
// newMethodに転送するように設定する。
// このとき、オリジナルのメソッドはselOriginalで渡されたセレクタで呼び出せるように設定する。
// 例： hokkMethod:@selector(keDown:) ofClass:[NSTextView class] withMethod:methodWrittenByMe keepingOriginalWith:@selector(originalKeyDown:)
//      NSTextViewのkeyDown:セレクタでメソッドが呼ばれた時、methodWrittenByMe出指定されたメソッドが呼び出されるようになる。
//      methodWrittenByMeが呼び出されたとき、オリジナルのものを呼び出したければ、[self originalKeyDown:...]とすればよい
+ (void) hookMethod:(SEL)sel ofClass:(Class)cls withMethod:(Method)newMethod keepingOriginalWith:(SEL)selOriginal{
    //オリジナルメソッド superクラスも見に行きメソッドを探す
    Method origMethod = class_getInstanceMethod(cls, sel);
    //オリジナルIMP by セレクタ
    IMP origImp_stret = class_getMethodImplementation_stret(cls, sel);
    class_replaceMethod(cls, sel, method_getImplementation(newMethod), method_getTypeEncoding(origMethod));
    // origImpはnilが帰る可能性がある。（サブクラスがそのメソッドを持たない場合） origImp_stretをselOriginalで呼び出せるようにする
    //NSTextViewの実装をkeyDown_:で呼び出せるようにしておく（keyDownをフックしたときに、転送できるように）
    class_addMethod(cls, selOriginal, origImp_stret, method_getTypeEncoding(origMethod));
}
@end
