//
//  XVimEval.m
//  XVim
//
//  Created by pebble on 2013/01/28.
//
//

#import "XVimEval.h"
#import "Logger.h"
#import "XVimWindow.h"
#import "NSTextView+VimOperation.h"

//
@implementation XVimEvalArg
@synthesize invar = _invar;
@synthesize rvar = _rvar;
@end

//
@implementation XVimEvalFunc

@synthesize funcName = _funcName;
@synthesize methodName = _methodName;

- (id)initWithFuncName:(NSString*)aFuncName MethodName:(NSString*)aMethodName
{
    self = [super init];
    if( self ){
        _funcName = aFuncName;
        _methodName = aMethodName;
    }
    return self;
}

@end

//
@implementation XVimEval
#define EVALFUNC(funcname,methodname) [[XVimEvalFunc alloc] initWithFuncName:funcname MethodName:methodname]
- (id)init
{
    self = [super init];
    if( self ){
        _evalFuncs = [[NSArray alloc] initWithObjects:
                      EVALFUNC(@"line", @"line:inWindow:"),
                      nil];
        
    }
    return self;
}

- (void)evaluateWhole:(XVimEvalArg*)args inWindow:(XVimWindow*)window
{
    // parse
    // 1) support only string
    // 2) support only string concatenation
    NSString* instr = args.invar;
    NSMutableString* evaled = [NSMutableString stringWithFormat:@""];
    NSUInteger index = 0;
    BOOL concat = FALSE;
    while( index < instr.length ){
        unichar uc = [instr characterAtIndex:index];
        if( uc == '"' ){
            // double quatation string : "abc.."
            ++index;
            while( index < instr.length ){
                unichar uc = [instr characterAtIndex:index];
                if( uc == '"' ){
                    ++index;
                    break;
                }
                [evaled appendFormat:@"%C",uc];
                ++index;
            }
        }
        else if( uc == ' ' ){
            // space
            ++index;
        }
        else if( uc == '.' ){
            // period
            concat = TRUE;
            ++index;
        }
        else {
            // begin function
            NSMutableString* cmd = [NSMutableString stringWithFormat:@""];
            while( index < instr.length ){
                unichar uc = [instr characterAtIndex:index];
                if( uc == ')' ){
                    [cmd appendFormat:@"%C",uc];
                    ++index;
                    break;
                }
                [cmd appendFormat:@"%C",uc];
                ++index;
            }
            XVimEvalArg* evalarg = [[XVimEvalArg alloc] init];
            evalarg.invar = cmd;
            [self evaluateFunc:evalarg inWindow:window];
            NSString* ret = (NSString*)evalarg.rvar;
            if( concat ){
                if( ret != nil ){
                    [evaled appendString:ret];
                }
                concat = FALSE;
            }
        }
    }
    args.rvar = [NSString stringWithFormat:@"\"%@\"",evaled];
}

- (void)evaluateFunc:(XVimEvalArg*)evalarg inWindow:(XVimWindow*)window
{
    evalarg.rvar = nil;
    
    // switch on function name
    for( XVimEvalFunc* evalfunc in _evalFuncs ){
        if( [evalarg.invar hasPrefix:evalfunc.funcName] ){
            SEL sel = NSSelectorFromString(evalfunc.methodName);
            if( [self respondsToSelector:sel] ){
                XVimEvalArg* evalarg_func = [[XVimEvalArg alloc] init];
                NSString* str = [evalarg.invar substringFromIndex:evalfunc.funcName.length];
                if( str.length > 2 &&
                   ( [str characterAtIndex:0] == '(' && [str characterAtIndex:str.length-1] == ')' ) )
                {
                    evalarg_func.invar = [NSString stringWithFormat:@"%@",
                                        [str substringWithRange:NSMakeRange(1, str.length-2)]];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [self performSelector:sel withObject:evalarg_func withObject:window];
#pragma clang diagnostic pop
                    evalarg.rvar = evalarg_func.rvar;
                } else {
                    // have no "()"
                }
                break;
            }
        }
    }
}

// each function implementation below
- (void)line:(XVimEvalArg*)evalarg inWindow:(XVimWindow*)window
{
    evalarg.rvar = nil;
    // support only "."
    if( [evalarg.invar isEqualToString:@"\".\""] ){
        evalarg.rvar = [NSString stringWithFormat:@"%lld", window.sourceView.currentLineNumber];
    }
}

@end
