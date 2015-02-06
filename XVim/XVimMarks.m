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
#import "XVim.h"

static NSString* LOCAL_MARKS = @"abcdefghijklmnopqrstuvwxyz'^.<>";
static NSString* FILE_MARKS = @"ABCDEFGHIJKLMNOPQRSTUVWXYZ";

@implementation XVimMarks{
    NSMutableDictionary* _localMarksDictionary;
    NSCharacterSet* _localMarkSet;
    NSCharacterSet* _fileMarkSet;
    // NSCharacterSet* _numberedMarkSet; // Currently Not Supported
    NSMutableDictionary* _fileMarks;
    enum {
        kJumpListMax = 100,
    };
    NSMutableArray* _jumplist;
    NSUInteger _jumpMarkIndex;
}

@synthesize fileMarks = _fileMarks;

+ (NSDictionary*)createEmptyLocalMarkDictionary{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    for( NSUInteger i = 0 ; i < LOCAL_MARKS.length; i++){
        unichar c = [LOCAL_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        [dic setObject:[[XVimMark alloc] init] forKey:name];
    }
    return dic;
}

+ (NSMutableDictionary*)createEmptyFileMarkDictionary{
    NSMutableDictionary* dic = [[NSMutableDictionary alloc] init];
    for( NSUInteger i = 0 ; i < FILE_MARKS.length; i++ ){
        unichar c = [FILE_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        [dic setObject:[[XVimMark alloc] init] forKey:name];
    }
    return dic;
}

- (id)init{
    if(self = [super init]){
        _fileMarks = [XVimMarks createEmptyFileMarkDictionary];
        _localMarksDictionary = [[NSMutableDictionary alloc] init];
        _localMarkSet = [NSCharacterSet characterSetWithCharactersInString:LOCAL_MARKS];
        _fileMarkSet = [NSCharacterSet characterSetWithCharactersInString:@"ABCDEFGHIJKLMNOPQRSTUVWXYZ"];
        _jumplist = [NSMutableArray array];
        _jumpMarkIndex = 0;
    }
    return self;
}

+ (NSString*)markDescriptionWithName:(NSString*)name Mark:(XVimMark*)mark
{
    return [NSString stringWithFormat:@"%@    %-5d%-7d%20@\n", (NSString*)name, (int)mark.line, (int)mark.column, mark.document];
}

- (NSString*)dumpMarksForDocument:(NSString*)document{
    NSDictionary* marks = [self marksForDocument:document];
    NSMutableString* str = [[NSMutableString alloc] init];
    for( NSUInteger i = 0 ; i < LOCAL_MARKS.length; i++){
        unichar c = [LOCAL_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        XVimMark* mark = [marks objectForKey:name];
        // Here we cast NSUInteger to int to dump. This is just because it may be NSNotFound and want make it dumped as "-1" not big value.
        // This is not accurate but should not be big problem for just dumping purpose.
        if( mark.document != nil ){
            [str appendString:[[self class] markDescriptionWithName:name Mark:mark]];
        }
    }
    return str;
}

- (NSString*)dumpFileMarks{
    NSDictionary* marks = _fileMarks;
    NSMutableString* str = [[NSMutableString alloc] init];
    for( NSUInteger i = 0 ; i < FILE_MARKS.length; i++){
        unichar c = [FILE_MARKS characterAtIndex:i];
        NSString* name = [NSString stringWithFormat:@"%C", c];
        XVimMark* mark = [marks objectForKey:name];
        // Here we cast NSUInteger to int to dump. This is just because it may be NSNotFound and want make it dumped as "-1" not big value.
        // This is not accurate but should not be big problem for just dumping purpose.
        if( mark.document != nil ){
            [str appendString:[[self class] markDescriptionWithName:name Mark:mark]];
        }
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
    if( c == '\'' || c == '`' ){
		return [[self marksForDocument:documentPath] objectForKey:@"'"];
    }else
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
    if( c == '\'' || c == '`' ){
		[self setLocalMark:mark forName:@"'"];
    }else
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
    [[marks objectForKey:[NSString stringWithFormat:@"%C", c]] setMark:mark];
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
    [[_fileMarks objectForKey:[NSString stringWithFormat:@"%C", c]] setMark:mark];
    return;
}

#pragma mark - JumpList
- (NSArray*)jumplist
{
    return _jumplist;
}

/**
 * support motion: "'", "`", "/", "?", "n", "N", "%", "(", ")", "{", "}", ":s", "L", "M", "H"
 * not support motion: "[[", "]]", ":tag", the commands that start editing a new file
 */
- (void)addToJumpListWithMark:(XVimMark*)aMark KeepJumpMarkIndex:(BOOL)keepJumpMarkIndex
{
    //DEBUG_LOG( @"line[%d] keepjump[%d]", aMark.line, keepJumpMarkIndex );
    NSMutableArray* aryDel = [NSMutableArray array];
    for( XVimMark* jump in _jumplist ){
        if( jump.line == aMark.line && [jump.document isEqualToString:aMark.document] ){
            [aryDel addObject:jump];
        }
    }
    [_jumplist removeObjectsInArray:aryDel];
    if( _jumplist.count > kJumpListMax ){
        // remove oldest jump mark
        [_jumplist removeObjectAtIndex:0];
    }
    [_jumplist addObject:aMark];
    
    if( !keepJumpMarkIndex ){
        // reset
        _jumpMarkIndex = 0;
    }
}

- (XVimMark*)incrementJumpMark
{
    if( _jumpMarkIndex <= 1 ) return nil;
    NSUInteger count = _jumplist.count;
    --_jumpMarkIndex;
    XVimMark* mark;
    @try {
        mark = _jumplist[count-_jumpMarkIndex];
    } @catch(NSException* e) {
        DEBUG_LOG( @"e[%@]", e );
    }
    return mark;
}

- (XVimMark*)decrementJumpMark:(BOOL*)pNeedUpdateMark
{
    NSUInteger count = _jumplist.count;
    if( _jumpMarkIndex >= count ) return nil;
    *pNeedUpdateMark = (_jumpMarkIndex == 0);
    ++_jumpMarkIndex;
    XVimMark* mark;
    @try {
        mark = _jumplist[count-_jumpMarkIndex];
    } @catch(NSException* e){
        DEBUG_LOG( @"e[%@]", e );
    }
    if( _jumpMarkIndex == 1 ){
        _jumpMarkIndex = 2;
    }
    return mark;
}

- (NSString*)dumpJumpList
{
    NSMutableString* str = [NSMutableString string];
    XVim* xvim = [XVim instance];
    [str appendString:@" jump line  col file/text\n"];
    NSArray* jumplist = xvim.marks.jumplist;
    NSInteger index = (NSInteger)jumplist.count - (NSInteger)_jumpMarkIndex;
    for( XVimMark* jump in jumplist ){
        [str appendFormat:@"%c%3ld %5ld %4ld %@\n", (index==0?'>':' '), labs(index), jump.line, jump.column, jump.document];
        --index;
    }
    if( _jumpMarkIndex == 0 ){
        [str appendString:@">\n"];
    }
    return str;
}

@end
