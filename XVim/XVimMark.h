//
//  XVimMark.h
//  XVim
//
//  Created by Suzuki Shuichiro on 3/21/13.
//
//

#import <Foundation/Foundation.h>

@interface XVimMark : NSObject
@property NSUInteger line;
@property NSUInteger column;
@property(strong) NSString* document;

- (id)initWithLine:(NSUInteger)line column:(NSUInteger)col document:(NSString*)doc;
- (id)initWithMark:(XVimMark*)mark;
@end


#define XVimMakeMark(line, col, doc) [[[XVimMark alloc] initWithLine:line column:col document:doc] autorelease]