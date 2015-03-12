//
//  XVimReplacePromptEvaluator.h
//  XVim
//
//  Created by Jeff Pearce on 2/19/15.
//  Copyright (c) 2015 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XVimEvaluator.h"

// This evaluator is waiting for the user to verify a replacement.
@interface XVimReplacePromptEvaluator : XVimEvaluator

@property (strong) NSString * replaceModeString;

- (instancetype)initWithWindow:(XVimWindow *)window replacementString:(NSString*)replacementString;

@end
