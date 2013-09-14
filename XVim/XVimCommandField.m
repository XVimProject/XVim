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
#import "Logger.h"

@interface XVimCommandField() {
	XVimWindow* _delegate;
}
@end

@implementation XVimCommandField

- (BOOL)becomeFirstResponder{
	[self setEditable:YES];
	[self setHidden:NO];
	return YES;
}

- (void)setDelegate:(XVimWindow*)delegate{
	_delegate = delegate;
}

// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
    if(flag) {
        color = [color colorWithAlphaComponent:0.5];
        NSPoint aPoint=NSMakePoint( rect.origin.x,rect.origin.y+rect.size.height/2);
        NSUInteger glyphIndex = [[self layoutManager] glyphIndexForPoint:aPoint inTextContainer:[self textContainer]];
        NSRect glyphRect = [[self layoutManager] boundingRectForGlyphRange:NSMakeRange(glyphIndex, 1)  inTextContainer:[self textContainer]];
        
        [color set];
        rect.size.width =rect.size.height/2;
        if(glyphRect.size.width > 0 && glyphRect.size.width < rect.size.width) 
            rect.size.width=glyphRect.size.width;
        
        NSRectFillUsingOperation( rect, NSCompositeSourceOver);
    } else {
        [self setNeedsDisplayInRect:self.visibleRect avoidAdditionalLayout:NO];
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

- (void)handleKeyStroke:(XVimKeyStroke*)keyStroke inWindow:(XVimWindow*)window{
	NSEvent *event = [keyStroke toEventwithWindowNumber:0 context:nil];
	[super keyDown:event];
}

@end
