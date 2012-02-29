//
//  XVimDeleteEvaluator.h
//  XVim
//
//  Created by Shuichiro Suzuki on 2/25/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "XVimTextObjectEvaluator.h"

// Handles input after 'd' or 'c'
@interface XVimDeleteEvaluator : XVimTextObjectEvaluator{
@private
    BOOL _insertModeAtCompletion;
    NSUInteger _repeat;
}
- (id)initWithRepeat:(NSUInteger)repeat insertModeAtCompletion:(BOOL)insertModeAtCompletion;
@end
