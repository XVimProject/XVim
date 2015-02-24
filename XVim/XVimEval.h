//
//  XVimEval.h
//  XVim
//
//  Created by pebble on 2013/01/28.
//
//

#import <Foundation/Foundation.h>

@class XVimWindow;

// @ref eval.c in original vim
@interface XVimEvalArg : NSObject
@property (strong) NSString* invar; // [in] in variable
@property (strong) id rvar; // [out] return variable
@end

//
@interface XVimEvalFunc : NSObject
@property (readonly) NSString* funcName;
@property (readonly) NSString* methodName;
@end

//
@interface XVimEval : NSObject
{
    NSArray* _evalFuncs;
}
- (void)evaluateWhole:(XVimEvalArg*)args inWindow:(XVimWindow*)window;
@end
