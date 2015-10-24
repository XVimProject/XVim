//
//  XVimCommandField.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandField.h"
#import "XVimKeyStroke.h"
#import "XVimWindow.h"
#import "XVimOptions.h"
#import "XVim.h"
#import "Logger.h"
#import "NSAttributedString+Geometrics.h"

@interface XVimCommandField() {
	XVimWindow* _delegate;
}
@end

@implementation XVimCommandField

-(id) init{
    self = [super init];
    if(self){
        [self setTextContainerInset:NSMakeSize(2.0,2.0)];
        [self setVerticallyResizable:YES];
    }
    return self;
}


- (NSSize)intrinsicContentSize{
    NSTextContainer* textContainer = [self textContainer];
    NSLayoutManager* layoutManager = [self layoutManager];
    [layoutManager ensureLayoutForTextContainer: textContainer];
    NSSize layoutSize = [layoutManager usedRectForTextContainer: textContainer].size;
    return NSMakeSize(NSViewNoInstrinsicMetric, layoutSize.height+self.textContainerInset.height);
}

- (BOOL)becomeFirstResponder{
	[self setEditable:YES];
	[self setHidden:NO];
    [self invalidateIntrinsicContentSize];
	return YES;
}

- (BOOL)resignFirstResponder{
	[self setEditable:NO];
	[self setHidden:YES];
    [self setString:@""];
    [self invalidateIntrinsicContentSize];
    return YES;
}

- (void)setDelegate:(XVimWindow*)delegate{
	_delegate = delegate;
}

// Drawing Caret
- (void)_drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color{
    color = [color colorWithAlphaComponent:0.5];
    NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
    NSUInteger glyphIndex = [[self layoutManager] glyphIndexForPoint:aPoint inTextContainer:[self textContainer]];
    NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[self textContainer]];
    
    rect.size.width =rect.size.height/2;
    if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
        rect.size.width=glyphRect.size.width;
    
    [self drawRect:[self visibleRect]];
    [color set];
    NSRectFillUsingOperation( rect, NSCompositeSourceOver);
}

- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
    if( [[[XVim instance] options] blinkcursor] ){
        if(!flag) {
            // Clear caret
            [self drawRect:[self visibleRect]];
        }
        [super drawInsertionPointInRect:rect color:color turnedOn:flag];
    }
}

- (void)keyDown:(NSEvent*)event {
	// Redirect to window -> XVimCommandLineEvaluator -> Back to here via handleKeyStroke
	// This is to get macro recording and key mapping support
    // TODO:
    // With this solution Input Method (Japanese or Chinese) does work but
    // the list box for it drawn in text view not in command line field.
    // Should be fixed.
	[_delegate handleKeyEvent:event];
}

- (void)didChangeText{
    [super didChangeText];
    [self invalidateIntrinsicContentSize];
}

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
    if (keyStroke.isPrintable) {
        [self insertText:keyStroke.xvimString];
        return;
    }
	NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
	[super keyDown:event];
}

@end
