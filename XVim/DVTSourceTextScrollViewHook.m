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
#import "NSObject+ExtraData.h"


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
    [self hook:@"viewWillMoveToWindow:"];
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

static NSString* XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW = @"XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW";


-(void)viewWillMoveToWindow:(NSWindow*)window
{
    if ( ![self boolForName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW] ) {
        [XVim.instance.options addObserver:self forKeyPath:@"guioptions" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:nil];
        __unsafe_unretained DVTSourceTextScrollView* weakSelf = (DVTSourceTextScrollView*)self;
        [ self xvim_performOnDealloc:^{
            DVTSourceTextScrollView *base = weakSelf;
            @try{
                [XVim.instance.options removeObserver:base forKeyPath:@"guioptions"];
            }
            @catch (NSException* exception){
                ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
                [Logger logStackTrace:exception];
            }
        }];
        [ self setBool:YES forName:XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW];
    }
    [ (DVTSourceTextScrollView*)self viewWillMoveToWindow_:window ];
}

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
        // Current problem we have is that when invoking "set guioptions=rb"
        // the alphaValue(=0) is not reflected to the view immideately.
        // After you resizing the view, the scroll bars appears.
        // I tried like [view needsDisplay:YES] or [view.verticalScroller needsDisplay:YES] and etc.
        // but any method call doesn't work...
        if( [XVim.instance.options.guioptions rangeOfString:@"r"].location == NSNotFound) {
            view.verticalScroller.alphaValue=0;
        }else{
            view.verticalScroller.alphaValue=1;
        }
        if( [XVim.instance.options.guioptions rangeOfString:@"b"].location == NSNotFound) {
            view.horizontalScroller.alphaValue=0;
        }else{
            view.horizontalScroller.alphaValue=1;
        }
    }
}

@end
