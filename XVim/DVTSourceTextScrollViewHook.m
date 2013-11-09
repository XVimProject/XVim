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
#import "Hooker.h"
#import "DVTSourceTextScrollViewHook.h"


@implementation DVTSourceTextScrollViewHook
+ (void)hook:(NSString*)method{
    NSString* cls = @"DVTSourceTextScrollView";
    NSString* thisCls = NSStringFromClass([self class]);
    [Hooker hookClass:cls method:method byClass:thisCls method:method];
}

+ (void)unhook:(NSString*)method{
    NSString* cls = @"DVTSourceTextScrollView";
    [Hooker unhookClass:cls method:method];
}

+ (void)hook{
    [self hook:@"initWithFrame:"];
    [self hook:@"dealloc"];
    [self hook:@"hasVerticalScroller"]; 
    [self hook:@"hasHorizontalScroller"]; 
    [self hook:@"observeValueForKeyPath:ofObject:change:context:"];
}

+ (void)unhook{
    // Never unhook comment outed methods because this class observes XVimOption value on init and remove observe on dealloc.
    // Unhooking between init and dealloc leads inconsistent state (and crash)
    // [self unhook:@"initWithFrame:"];
    // [self unhook:@"dealloc"];
    [self unhook:@"hasVerticalScroller"]; 
    [self unhook:@"hasHorizontalScroller"]; 
    // [self unhook:@"observeValueForKeyPath:ofObject:change:context:"];
}

- (id)initWithFrame:(NSRect)rect{
    DVTSourceTextScrollView* base = (DVTSourceTextScrollView*)self;
    id obj = [base initWithFrame_:rect];
    if( nil != obj ){
        TRACE_LOG(@"%p initWithFrame", obj);
        [XVim.instance.options addObserver:obj forKeyPath:@"guioptions" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
    }
    return (DVTSourceTextScrollViewHook*)obj;
}

// This pragma is for suppressing warning that the dealloc method does not call [super dealloc]. ([base dealloc_] calls [super dealloc] so we do not need it)
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wall"
- (void)dealloc{
    DVTSourceTextScrollView *base = (DVTSourceTextScrollView*)self;
    @try{
        TRACE_LOG(@"%p dealloc", base);
        [XVim.instance.options removeObserver:self forKeyPath:@"guioptions"];
    }
    @catch (NSException* exception){
        ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        [Logger logStackTrace:exception];
    }
    [base dealloc_];
    return;
}
#pragma GCC diagnostic pop

- (BOOL)hasVerticalScroller{
    if( [XVim.instance.options.guioptions rangeOfString:@"r"].location == NSNotFound) {
        return NO;
    }else{
        return YES;
    }
}

- (BOOL)hasHorizontalScroller{
    if( [XVim.instance.options.guioptions rangeOfString:@"b"].location == NSNotFound) {
        return NO;
    }else{
        return YES;
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context {
	if([keyPath isEqualToString:@"guioptions"]){
        NSScrollView* view = (NSScrollView*)self;
        // Just updating the scrollers state.
        if( [XVim.instance.options.guioptions rangeOfString:@"r"].location == NSNotFound) {
            [view setHasVerticalScroller:NO];
        }else{
            [view setHasVerticalScroller:YES];
        }
        if( [XVim.instance.options.guioptions rangeOfString:@"b"].location == NSNotFound) {
            [view setHasHorizontalScroller:NO];
        }else{
            [view setHasHorizontalScroller:YES];
        }
    }
}

@end
