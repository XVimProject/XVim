//
//  XVimTaskRunner.h
//  XVim
//
//  Created by Ant on 02/09/2012.
//
//

#import <Foundation/Foundation.h>

@interface XVimTaskRunner : NSObject
+(NSString*) runScript:(NSString*)scriptName withInput:(NSString*)input;
@end
