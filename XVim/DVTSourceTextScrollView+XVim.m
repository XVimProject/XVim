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
#import "NSObject+ExtraData.h"
#import "NSObject+XVimAdditions.h"


@implementation DVTSourceTextScrollView(XVim)
+ (void)xvim_initialize{
    [self xvim_swizzleInstanceMethod:@selector(viewWillMoveToWindow:) with:@selector(xvim_viewWillMoveToWindow:)];
    [self xvim_swizzleInstanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:) with:@selector(xvim_observeValueForKeyPath:ofObject:change:context:)];
}

+ (void)xvim_finalize{
    [self xvim_swizzleInstanceMethod:@selector(viewWillMoveToWindow:) with:@selector(xvim_viewWillMoveToWindow:)];
    // TODO: To unhook observe... method, we have to removeObserver from XVimOptions.
    //       We already have PerformOnDealloc object associated to this obj, we just call it then call this unhook method.
    //[self xvim_swizzleInstanceMethod:@selector(observeValueForKeyPath:ofObject:change:context:) with:@selector(xvim_observeValueForKeyPath:ofObject:change:context:)];
}

static NSString* XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW = @"XVIM_INSTALLED_OBSERVERS_DVTSOURCETEXTSCROLLVIEW";

-(void)xvim_viewWillMoveToWindow:(NSWindow*)window
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
        // Fix text stretching bug when scrolling
        self.contentView.copiesOnScroll = NO;
    }
    [self xvim_viewWillMoveToWindow:window ];
}

- (void)xvim_observeValueForKeyPath:(NSString *)keyPath  ofObject:(id)object  change:(NSDictionary *)change  context:(void *)context {
    if([keyPath isEqualToString:@"guioptions"]){
        // Just updating the scrollers state.
        // Current problem we have is that when invoking "set guioptions=rb"
        // the alphaValue(=0) is not reflected to the view immideately.
        // After you resizing the view, the scroll bars appears.
        // I tried like [view needsDisplay:YES] or [view.verticalScroller needsDisplay:YES] and etc.
        // but any method call doesn't work...
        if( [XVim.instance.options.guioptions rangeOfString:@"r"].location == NSNotFound) {
            self.verticalScroller.alphaValue=0;
        }else{
            self.verticalScroller.alphaValue=1;
        }
        if( [XVim.instance.options.guioptions rangeOfString:@"b"].location == NSNotFound) {
            self.horizontalScroller.alphaValue=0;
        }else{
            self.horizontalScroller.alphaValue=1;
        }
    }
}

@end
