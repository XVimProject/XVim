//
//  XVimChildEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 21/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

@class XVimKeyStroke;
#import "XVimEvaluator.h"

/**
 * This class can be used as a evaluate any argument.
 * For example 'f','F','m' takes argument to fix its motion.
 * In these case XVimNormalEvaluator create an object of this or subclass of this class and return it as a next evaluator.
 * After argument is provided onChildComplete method will use the object to know what the argument is.
 * XVimArgumentEvaluator has keyStroke property and it has the provided key input as the argument.
 * If you want to keep more information in the XVimArgumentEvaluator you just can subclass it.
 * Typical usage of subclassing is following
 *   1. Create subclass of XVimArgumentEvaluator
 *   2. Add any property to keep information to know what the argument is for its parent evaluator.
 *   3. Override onArgumentProvided method to process the key stroke and store infomation to the property
 *   4. Use the property to do some operation for the result of the argument onChildComplete method in the parent evaluator.
 * 
 * XVimRegisterEvaluator is good example.
 *
 * Do not try to override eval: method
 **/
@interface XVimArgumentEvaluator : XVimEvaluator {
}
@property(strong) XVimKeyStroke* keyStroke;
- (XVimEvaluator*)onArgumentProvided:(XVimKeyStroke*)key;
@end
