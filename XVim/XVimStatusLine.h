//
//  XVimStatusLine.h
//  XVim
//
//  Created by Shuichiro Suzuki on 4/26/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface XVimLaststatusTransformer : NSValueTransformer
@end

@interface XVimStatusLine : NSTextField
- (id)initWithString:(NSString*)str;
@end
