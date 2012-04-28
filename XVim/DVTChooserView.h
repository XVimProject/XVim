//
//  DVTChooserView.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "DVTBorderedView.h"

@interface DVTChooserView : DVTBorderedView
{
    NSMatrix *_buttonMatrix;
    NSIndexSet *_selectionIndexes;
    NSMutableArray *_choices;
    //id <DVTChooserViewDelegate> _delegate;
    int _justification;
    int _gradientStyle;
    BOOL _allowsMultipleSelection;
    BOOL _allowsEmptySelection;
    BOOL _choicesFillWidth;
}

+ (id)keyPathsForValuesAffectingSelectedChoices;
+ (id)keyPathsForValuesAffectingSelectedChoice;
+ (id)keyPathsForValuesAffectingSelectedIndex;
+ (struct CGSize)defaultMinimumButtonSize;
+ (struct CGSize)defaultButtonSize;
+ (void)initialize;
//@property id <DVTChooserViewDelegate> delegate; // @synthesize delegate=_delegate;
@property int gradientStyle; // @synthesize gradientStyle=_gradientStyle;
@property BOOL choicesFillWidth; // @synthesize choicesFillWidth=_choicesFillWidth;
@property BOOL allowsEmptySelection; // @synthesize allowsEmptySelection=_allowsEmptySelection;
@property BOOL allowsMultipleSelection; // @synthesize allowsMultipleSelection=_allowsMultipleSelection;
@property int justification; // @synthesize justification=_justification;
//@property NSMatrix *_buttonMatrix; // @synthesize _buttonMatrix;
@property(readonly) NSArray *grabRects;
@property(readonly) struct CGRect grabRect;
@property(readonly) NSMutableArray *mutableChoices;
- (void)updateBoundContent;
@property(copy) NSArray *choices;
- (void)updateBoundSelectedObjects;
- (void)updateBoundSelectionIndexes;
@property(copy) NSArray *selectedChoices;
//@property DVTChoice *selectedChoice;
@property unsigned long long selectedIndex;
@property(copy) NSIndexSet *selectionIndexes; // @synthesize selectionIndexes=_selectionIndexes;
- (void)setBorderSides:(int)arg1;
- (void)layoutTopDown;
- (void)_chooserButtonClicked:(id)arg1;
- (void)drawBorderInRect:(struct CGRect)arg1;
- (struct CGRect)_exposedRectLeft;
- (struct CGRect)_exposedRect;
- (void)encodeWithCoder:(id)arg1;
- (id)initWithCoder:(id)arg1;
- (id)dvtExtraBindings;
- (id)initWithFrame:(struct CGRect)arg1;
- (void)_commonInit;
- (void)_configureButtonMatrix;

- (void)setGradientStyle_:(int)style;
@end

