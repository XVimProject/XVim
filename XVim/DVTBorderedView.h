//
//  DVTBorderedView.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DVTBorderedView : NSView
{
    NSColor *_topBorderColor;
    NSColor *_bottomBorderColor;
    NSColor *_leftBorderColor;
    NSColor *_rightBorderColor;
    NSColor *_topInactiveBorderColor;
    NSColor *_bottomInactiveBorderColor;
    NSColor *_leftInactiveBorderColor;
    NSColor *_rightInactiveBorderColor;
    NSColor *_shadowColor;
    NSColor *_backgroundColor;
    NSColor *_inactiveBackgroundColor;
    NSGradient *_backgroundGradient;
    NSGradient *_inactiveBackgroundGradient;
    NSView *_contentView;
    int _verticalContentViewResizingMode;
    int _horizontalContentViewResizingMode;
    int _borderSides;
    int _shadowSides;
}
@property int verticalContentViewResizingMode; // @synthesize verticalContentViewResizingMode=_verticalContentViewResizingMode;
@property(copy) NSColor *topInactiveBorderColor; // @synthesize topInactiveBorderColor=_topInactiveBorderColor;
@property(copy) NSColor *topBorderColor; // @synthesize topBorderColor=_topBorderColor;
@property int shadowSides; // @synthesize shadowSides=_shadowSides;
@property(copy) NSColor *shadowColor; // @synthesize shadowColor=_shadowColor;
@property(copy) NSColor *rightInactiveBorderColor; // @synthesize rightInactiveBorderColor=_rightInactiveBorderColor;
@property(copy) NSColor *rightBorderColor; // @synthesize rightBorderColor=_rightBorderColor;
@property(copy) NSColor *leftInactiveBorderColor; // @synthesize leftInactiveBorderColor=_leftInactiveBorderColor;
@property(copy) NSColor *leftBorderColor; // @synthesize leftBorderColor=_leftBorderColor;
@property(copy) NSGradient *inactiveBackgroundGradient; // @synthesize inactiveBackgroundGradient=_inactiveBackgroundGradient;
@property(copy) NSColor *inactiveBackgroundColor; // @synthesize inactiveBackgroundColor=_inactiveBackgroundColor;
@property int horizontalContentViewResizingMode; // @synthesize horizontalContentViewResizingMode=_horizontalContentViewResizingMode;
@property(assign) NSView *contentView; // @synthesize contentView=_contentView;
@property(copy) NSColor *bottomInactiveBorderColor; // @synthesize bottomInactiveBorderColor=_bottomInactiveBorderColor;
@property(copy) NSColor *bottomBorderColor; // @synthesize bottomBorderColor=_bottomBorderColor;

// This property seems to take bit flag
// 1:left,  2:right  4:top  8:bottom 
// So 0x03 means left and right to boe bordered
@property int borderSides; // @synthesize borderSides=_borderSides;

@property(copy) NSGradient *backgroundGradient; // @synthesize backgroundGradient=_backgroundGradient;
@property(copy) NSColor *backgroundColor; // @synthesize backgroundColor=_backgroundColor;
- (void)_windowKeyMainStateChanged:(id)arg1;
- (void)viewWillMoveToWindow:(id)arg1;
- (void)drawRect:(struct CGRect)arg1;
- (void)drawBorderInRect:(struct CGRect)arg1;
- (void)drawBackgroundInRect:(struct CGRect)arg1;
- (BOOL)_isInactive;
- (void)layoutBottomUp;
- (void)layoutTopDown;
- (void)_contentViewFrameDidChange:(id)arg1;
- (struct CGSize)frameSizeForContentSize:(struct CGSize)arg1;
- (struct CGSize)boundSizeForContentSize:(struct CGSize)arg1;
@property(readonly) struct CGRect contentRect;
- (struct CGRect)_contentRectExcludingShadow;
//- (CDStruct_bf6d4a14)_contentInset;
//- (CDStruct_bf6d4a14)_borderInset;
//- (CDStruct_bf6d4a14)_shadowInset;
- (BOOL)isShowingShadow;
- (void)setAllInactiveBordersToColor:(id)arg1;
- (void)setAllBordersToColor:(id)arg1;
- (void)setShadowSide:(int)arg1;
- (void)_setBorderSides:(int)arg1;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)initWithFrame:(struct CGRect)arg1;

@end
