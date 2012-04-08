//
//  XVimCommandField.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/29/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimCommandField.h"
#import "NSTextView+VimMotion.h"
#import "Logger.h"

@interface XVimCommandField(){
    BOOL _askingMode;
    NSString* _msg;
    id msgOwner;
    SEL responseHandler;
}
@end

@implementation XVimCommandField
@synthesize delegate;

- (void)answered:(id)sender{
    METHOD_TRACE_LOG();
}

- (id)initWithFrame:(NSRect)frameRect{
    if( self = [super initWithFrame:frameRect] ){
        _askingMode = NO;
    }
    return self;
}

- (void)dealloc{
    [_msg release];
    [super dealloc];
}

- (void)onLoseFocus{
    [self setString:@""];
    [self setEditable:NO];
    [self setHidden:YES];
}

- (BOOL)resignFirstResponder{
    if( _askingMode ){
        return NO;
    }
    [self onLoseFocus];
    return YES;
}

- (void)doCommandBySelector:(SEL)aSelector{
    if( @selector(complete:) == aSelector|| @selector(cancelOperation:) == aSelector){
        if( [self.delegate commandCanceled] ){
            [self onLoseFocus];
        }
        return;
    }
    [super doCommandBySelector:aSelector];
}

- (void)insertText:(id)insertString{
    if( [insertString length] != 1 ){
        //Only supports one by one input at the moment
        return;
    }else if( isNewLine([insertString characterAtIndex:0])){
        if( [self.delegate commandFixed:[self string]] ){
            [self onLoseFocus];
        }
        return;
    }else if( [insertString characterAtIndex:0] == '\t') {
        // Tab completion will be implemented here.
        return;
    }
    [super insertText:insertString]; 
}
// Drawing Caret
- (void)drawInsertionPointInRect:(NSRect)rect color:(NSColor*)color turnedOn:(BOOL)flag{
    if(flag){
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
        [self setNeedsDisplayInRect:[self visibleRect] avoidAdditionalLayout:NO];
    }
}

- (void)ask:(NSString*)msg owner:(id)owner handler:(SEL)selector option:(ASKING_OPTION)opt{
    _askingMode=YES;
    [_msg release];
    _msg = [msg retain];
    msgOwner = owner; // Weak reference
    responseHandler = selector;
    [self setString:_msg];
    [self setEditable:YES];
}

@end
