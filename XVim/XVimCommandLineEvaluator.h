//
//  XVimCommandEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@class XVimHistoryHandler;

typedef XVimEvaluator* (^OnCompleteHandler) (NSString* command, id* result); // returned "result" will be stored in evaluationResult
typedef void (^OnKeyPressHandler) (NSString* command);

@interface XVimCommandLineEvaluator : XVimEvaluator
@property(strong) id evalutionResult;

- (id)initWithWindow:(XVimWindow *)window
		 firstLetter:(NSString*)firstLetter
			 history:(XVimHistoryHandler*)history
		  completion:(OnCompleteHandler)completeHandler
		  onKeyPress:(OnKeyPressHandler)keyPressHandler;

- (void)appendString:(NSString*)str;
- (XVimEvaluator*)execute;
@end
