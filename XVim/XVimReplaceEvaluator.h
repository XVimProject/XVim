//
//  XVimReplaceEvaluator.h
//  XVim
//
//  Created by Martin Conte Mac Donell on 12/14/14.
//

#import "XVimInsertEvaluator.h"

@interface XVimReplaceEvaluator : XVimInsertEvaluator

- (id)initWithWindow:(XVimWindow *)window oneCharMode:(BOOL)oneCharMode mode:(XVimInsertionPoint)mode;

@end
