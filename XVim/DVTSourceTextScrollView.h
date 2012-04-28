//
//  DVTSourceTextScrollView.h
//  XVim
//
//  Created by Suzuki Shuichiro on 4/27/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DVTSourceTextScrollView : NSScrollView
{
    id /*<DVTSourceTextScrollViewDelegate>*/ _delegate;
    /*DVTComparisonSplitView*/ NSView *_comparisonSplitView;
    BOOL _scrollingHorizontally;
}

//@property DVTComparisonSplitView *comparisonSplitView; // @synthesize comparisonSplitView=_comparisonSplitView;
//@property id <DVTSourceTextScrollViewDelegate> delegate; // @synthesize delegate=_delegate;
- (void)_doScroller:(id)arg1 hitPart:(long long)arg2 multiplier:(double)arg3;
- (void)scrollWheelHorizontal:(id)arg1;
- (void)reflectScrolledClipView:(id)arg1;
- (void)scrollWheel:(id)arg1;
- (void)viewDidEndLiveResize;

- (void)viewDidMoveToSuperview_;
@end
