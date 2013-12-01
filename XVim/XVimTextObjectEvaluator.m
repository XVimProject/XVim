//  XVim
//
//  Created by Tomas Lundell on 8/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"
#import "XVimWindow.h"
#import "XVimKeyStroke.h"
#import "XVimKeymapProvider.h"

@interface XVimTextObjectEvaluator() {
    BOOL   _inner;
    MOTION _textobject;
    BOOL _bigword;
}
@end

@implementation XVimTextObjectEvaluator

- (id)initWithWindow:window inner:(BOOL)inner{
	if (self = [super initWithWindow:window]) {
        _inner = inner;
        _bigword = NO;
	}
	return self;
}

- (void)dealloc{
    [super dealloc];
}

- (XVimMotion *)motion {
    XVimMotionOptions opt = _inner ? MOPT_TEXTOBJECT_INNER : MOPT_NONE;
    opt |= _bigword ? MOPT_BIGWORD : MOPT_NONE;
    return XVIM_MAKE_MOTION(_textobject, CHARACTERWISE_INCLUSIVE, opt, [self numericArg]);
}

- (XVimEvaluator*)defaultNextEvaluator{
    return nil;
}

- (NSString *)modeString
{
    return self.parent.modeString;
}

- (void)didEndHandler
{
    [self.parent.argumentString setString:@""];
    [super didEndHandler];
}

- (CGFloat)insertionPointHeightRatio{
    return 0.5;
}

- (BOOL)isRelatedTo:(XVimEvaluator*)other {
	return [super isRelatedTo:other] || other == self.parent;
}

- (XVimKeymap*)selectKeymapWithProvider:(id<XVimKeymapProvider>)keymapProvider {
	return [keymapProvider keymapForMode:XVIM_MODE_OPERATOR_PENDING];
}

- (XVimEvaluator*)b{
    _textobject = TEXTOBJECT_PARENTHESES;
    return nil;
}

- (XVimEvaluator*)B{
    _textobject = TEXTOBJECT_BRACES;
    return nil;
}

-(XVimEvaluator*)p{
    _textobject = TEXTOBJECT_PARAGRAPH;
    return nil;
}

- (XVimEvaluator*)w{
    _textobject = TEXTOBJECT_WORD;
    return nil;
}

- (XVimEvaluator*)W{
    _textobject = TEXTOBJECT_WORD;
    _bigword = YES;
    return nil;
}

- (XVimEvaluator*)LSQUAREBRACKET{
    _textobject = TEXTOBJECT_SQUAREBRACKETS;
    return nil;
}

- (XVimEvaluator*)RSQUAREBRACKET{
	return [self LSQUAREBRACKET];
}

- (XVimEvaluator*)LBRACE{
	return [self B];
}

- (XVimEvaluator*)RBRACE{
	return [self B];
}

- (XVimEvaluator*)LESSTHAN{
    _textobject = TEXTOBJECT_ANGLEBRACKETS;
    return nil;
}

- (XVimEvaluator*)GREATERTHAN{
	return [self LESSTHAN];
}

- (XVimEvaluator*)LPARENTHESIS{
	return [self b];
}

- (XVimEvaluator*)RPARENTHESIS{
	return [self b];
}

- (XVimEvaluator*)SQUOTE{
    _textobject = TEXTOBJECT_SQUOTE;
    return nil;
}

- (XVimEvaluator*)DQUOTE{
    _textobject = TEXTOBJECT_DQUOTE;
    return nil;
}

- (XVimEvaluator*)BACKQUOTE{
    _textobject = TEXTOBJECT_BACKQUOTE;
    return nil;
}

- (XVimEvaluator*)ESC{
    return nil;
}

@end
