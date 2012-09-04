//
//  XVimTaskRunner.m
//  XVim
//
//  Created by Ant on 02/09/2012.
//
//

#import "XVimTaskRunner.h"

// define some LLVM3 macros if the code is compiled with a different compiler (ie LLVMGCC42)
#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED 1
#endif // __has_feature(objc_arc)


#if	ARC_ENABLED

#ifndef	RETAIN
#define	RETAIN(object)		(object)
#endif
#ifndef	RELEASE
#define	RELEASE(object)
#endif
#ifndef	AUTORELEASE
#define	AUTORELEASE(object)	(object)
#endif

#else

#ifndef	RETAIN
#define	RETAIN(object)		[(object) retain]
#endif
#ifndef	RELEASE
#define	RELEASE(object)		[(object) release]
#endif
#ifndef	AUTORELEASE
#define	AUTORELEASE(object)	[(object) autorelease]
#endif
#endif


@implementation XVimTaskRunner
+(NSString*) runScript:(NSString*)scriptAndArgs withInput:(NSString*)input
{
    NSTask *task;
    task = AUTORELEASE([[NSTask alloc] init]);
    [task setLaunchPath: @"/bin/sh"];

    NSArray *arguments = [ NSArray arrayWithObjects:@"-c",scriptAndArgs, nil];
    [task setArguments: arguments];

    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput: outputPipe];
    NSPipe *inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    
    NSFileHandle *inputFile = nil;
    NSFileHandle *outputFile = nil;
    outputFile = [outputPipe fileHandleForReading];
    if (input!=nil)
    {
        inputFile = [inputPipe fileHandleForWriting];
    }
    
    [task launch];
    
    if (input!=nil)
    {
        NSData *inputData = [ input dataUsingEncoding:NSUTF8StringEncoding ];
        [ inputFile writeData:inputData ];
        [ inputFile closeFile ];
    }
    NSData *outputData = [outputFile readDataToEndOfFile];
    
    return AUTORELEASE([[NSString alloc] initWithData: outputData encoding: NSUTF8StringEncoding]);
}
@end
