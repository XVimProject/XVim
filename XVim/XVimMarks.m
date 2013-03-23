//
//  XVimMarks.m
//  XVim
//
//  Created by Suzuki Shuichiro on 3/21/13.
//
//

#import "XVimMark.h"
#import "XVimMarks.h"
#import "Logger.h"

static NSString* LOCAL_MARKS = @"abcdefghijklmnopqrstuvwxyz'`^.<>";
static NSString* FILE_MARKS = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";

@implementation XVimMarks{
    NSMutableDictionary* _localMarksDictionary;
    NSCharacterSet* _localMarkSet;
    NSCharacterSet* _fileMarkSet;
    // NSCharacterSet* _numberedMarkSet; // Currently Not Supported
}

@synthesize fileMarks = _fileMarks;

+ (NSDictionary*)createEmptyLocalMarkDictionary{
    NSMutableDictionary* dic = [[[NSMutableDictionary alloc] init] autorelease];
    for( NSUInteger i = 0 ; i < LOCAL_MARKS.length; i++){
        unichar c = [LOCAL_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        [dic setObject:[[[XVimMark alloc] init] autorelease] forKey:name];
    }
    [dic setObject:[dic objectForKey:@"`"] forKey:@"'"]; // Make these marks same
    return dic;
}

+ (NSDictionary*)createEmptyFileMarkDictionary{
    NSMutableDictionary* dic = [[[NSMutableDictionary alloc] init] autorelease];
    for( NSUInteger i = 0 ; i < FILE_MARKS.length; i++ ){
        unichar c = [FILE_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        [dic setObject:[[[XVimMark alloc] init] autorelease] forKey:name];
    }
    return dic;
}

- (id)init{
    if(self = [super init]){
        _fileMarks = [[XVimMarks createEmptyFileMarkDictionary] retain];
        _localMarksDictionary = [[NSMutableDictionary alloc] init];
        _localMarkSet = [[NSCharacterSet characterSetWithCharactersInString:LOCAL_MARKS] retain];
        _fileMarkSet = [[NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"] retain];
    }
    return self;
}

- (void)dealloc{
    [_fileMarks release];
    [_localMarksDictionary release];
    [_localMarkSet release];
    [_fileMarkSet release];
    [super dealloc];
}

- (NSString*)dumpMarksForDocument:(NSString*)document{
    NSDictionary* marks = [self marksForDocument:document];
    NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
    [str appendString:@"Mark Line Column File\n"];
    for( NSUInteger i = 0 ; i < LOCAL_MARKS.length; i++){
        unichar c = [LOCAL_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        XVimMark* mark = [marks objectForKey:name];
        // Here we cast NSUInteger to int to dump. This is just because it may be NSNotFound and want make it dumped as "-1" not big value.
        // This is not accurate but should not be big problem for just dumping purpose.
        [str appendFormat:@"%@    %-5d%-7d%20@\n", (NSString*)name, (int)mark.line, (int)mark.column, mark.document];
    }
    return str;
}

- (NSString*)dumpFileMarks{
    NSDictionary* marks = _fileMarks;
    NSMutableString* str = [[[NSMutableString alloc] init] autorelease];
    [str appendString:@"Mark Line Column File\n"];
    for( NSUInteger i = 0 ; i < FILE_MARKS.length; i++){
        unichar c = [FILE_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        XVimMark* mark = [marks objectForKey:name];
        // Here we cast NSUInteger to int to dump. This is just because it may be NSNotFound and want make it dumped as "-1" not big value.
        // This is not accurate but should not be big problem for just dumping purpose.
        [str appendFormat:@"%@    %-5d%-7d%20@\n", (NSString*)name, (int)mark.line, (int)mark.column, mark.document];
    }
    return str;
    
}

- (XVimMark*)markForName:(NSString*)name forDocument:(NSString *)documentPath{
    NSAssert(nil != name, @"name can not be nil");
    NSAssert(nil != documentPath, @"documentPath can not be nil");
    
    if( [name length] == 0 ){
        DEBUG_LOG(@"The length of name is 0");
        return nil;
    }
    
    unichar c = [name characterAtIndex:0];
    if( [_localMarkSet characterIsMember:c] ){
        return [[self marksForDocument:documentPath] objectForKey:name];
    }else if( [_fileMarkSet characterIsMember:c] ){
        return [_fileMarks objectForKey:name];
    }else{
        TRACE_LOG(@"Unsupported name for mark is passed");
        return nil;
    }
}

- (void)setMark:(XVimMark*)mark forName:(NSString*)name{
    NSAssert(nil != mark, @"mark can not be nil");
    NSAssert(nil != name, @"name can not be nil");
    NSAssert(nil != mark.document, @"documentPath can not be nil");
    
    if( [name length] == 0 ){
        DEBUG_LOG(@"The length of name is 0");
        return;
    }
    unichar c = [name characterAtIndex:0];
    if( [_localMarkSet characterIsMember:c] ){
        [self setLocalMark:mark forName:name];
    }else if( [_fileMarkSet characterIsMember:c] ){
        [self setFileMark:mark forName:name];
    }else{
        TRACE_LOG(@"Unsupported name for mark is passed");
    }
    
    return;
}

- (NSDictionary*)marksForDocument:(NSString*)documentPath{
    NSAssert(nil != documentPath, @"documentPath can not be nil");
    if( nil == [_localMarksDictionary objectForKey:documentPath] ){
        [_localMarksDictionary setObject:[XVimMarks createEmptyLocalMarkDictionary] forKey:documentPath];
    }
    NSDictionary* marks = [_localMarksDictionary objectForKey:documentPath];
    
    NSAssert( nil != marks, @"This should not happen");
    return marks;
}


- (void)setLocalMark:(XVimMark*)mark forName:(NSString*)name{
    NSAssert(nil != mark, @"mark can not be nil");
    NSAssert(nil != name, @"name can not be nil");
    NSAssert(nil != mark.document, @"documentPath can not be nil");
    
    if( [name length] == 0 ){
        DEBUG_LOG(@"The length of name is 0");
        return;
    }
    unichar c = [name characterAtIndex:0];
    if( ![_localMarkSet characterIsMember:c] ){
        TRACE_LOG(@"Local Mark '%C' not found", c);
        return;
    }
    
    if( nil == [_localMarksDictionary objectForKey:mark.document] ){
        [_localMarksDictionary setObject:[XVimMarks createEmptyLocalMarkDictionary] forKey:mark.document];
    }
    NSDictionary* marks = [_localMarksDictionary objectForKey:mark.document];
    [[marks objectForKey:[NSString stringWithFormat:@"%C", c]] initWithMark:mark];
    return;
}

- (void)setFileMark:(XVimMark*)mark forName:(NSString*)name{
    NSAssert(nil != mark, @"mark can not be nil");
    NSAssert(nil != name, @"name can not be nil");
    NSAssert(nil != mark.document, @"documentPath can not be nil");
    
    if( [name length] == 0 ){
        DEBUG_LOG(@"The length of name is 0");
        return;
    }
    unichar c = [name characterAtIndex:0];
    if( ![_fileMarkSet characterIsMember:c] ){
        TRACE_LOG(@"File Mark '%C' not found", c);
        return;
    }
    
    // Never replace object in dictionary (just change the value of the mark)
    [[_fileMarks objectForKey:[NSString stringWithFormat:@"%C", c]] initWithMark:mark];
    return;
}
@end
