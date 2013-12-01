//
//  DVTSourceTextScrollViewHook.m
//  XVim
//
//  Created by Suzuki Shuichiro on 11/8/13.
//
//

#import "Logger.h"
#import "XVim.h"
#import "XVimOptions.h"
#import "DVTSourceTextScrollView+XVim.h"
#import "NSObject+XVimAdditions.h"

@implementation DVTSourceTextScrollView (XVim)

+ (void)xvim_initialize
{
    if (self == [DVTSourceTextScrollView class]) {
#define swizzle(sel) \
        [self xvim_swizzleInstanceMethod:@selector(sel) with:@selector(xvim_##sel)]

        swizzle(initWithFrame:);
        swizzle(dealloc);
        swizzle(hasVerticalScroller);
        swizzle(hasHorizontalScroller);
        swizzle(observeValueForKeyPath:ofObject:change:context:);

#undef swizzle
    }
}

- (instancetype)xvim_initWithFrame:(NSRect)rect
{
    if ((self = [self xvim_initWithFrame:rect])) {
        TRACE_LOG(@"%p initWithFrame", self);
        [XVim.instance.options addObserver:self forKeyPath:@"guioptions"
                                   options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_xvim_statusChanged:)
                                                     name:XVimEnabledStatusChangedNotification object:nil];
    }
    return self;
}

- (void)xvim_dealloc
{
    @try {
        TRACE_LOG(@"%p dealloc", self);
        [[NSNotificationCenter defaultCenter] removeObserver:self];
        [XVim.instance.options removeObserver:self forKeyPath:@"guioptions"];
    }
    @catch (NSException* exception){
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    [self xvim_dealloc];
}

- (void)_xvim_statusChanged:(id)unused
{
    if (XVim.instance.disabled) {
        self.hasHorizontalScroller = YES;
        self.hasVerticalScroller = YES;
    }
}

- (BOOL)xvim_hasVerticalScroller
{
    if (XVim.instance.disabled) {
        return [self xvim_hasVerticalScroller];
    }
    return [XVim.instance.options.guioptions rangeOfString:@"r"].location != NSNotFound;
}

- (BOOL)xvim_hasHorizontalScroller
{
    if (XVim.instance.disabled) {
        return [self xvim_hasHorizontalScroller];
    }
    return [XVim.instance.options.guioptions rangeOfString:@"b"].location != NSNotFound;
}

- (void)xvim_observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                             change:(NSDictionary *)change context:(void *)context
{
    if (object != XVim.instance.options) {
        return [self xvim_observeValueForKeyPath:keyPath ofObject:object
                                          change:change context:context];
    }
    if ([keyPath isEqualToString:@"guioptions"]) {
        // Just updating the scrollers state.
        self.hasHorizontalScroller = self.hasHorizontalScroller;
        self.hasVerticalScroller = self.hasVerticalScroller;
    }
}

@end
