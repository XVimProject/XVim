//
//  XVimCommandEvaluator.h
//  XVim
//
//  Created by Tomas Lundell on 14/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimEvaluator.h"

@class XVimHistoryHandler;

typedef XVimEvaluator* (^OnCompleteHandler) (NSString* command);
typedef void (^OnKeyPressHandler) (NSString* command);

@interface XVimCommandLineEvaluator : XVimEvaluator

- (id)initWithWindow:(XVimWindow *)window
		 firstLetter:(NSString*)firstLetter
			 history:(XVimHistoryHandler*)history
		  completion:(OnCompleteHandler)completeHandler
		  onKeyPress:(OnKeyPressHandler)keyPressHandler;
@end
