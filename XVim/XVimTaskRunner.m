//
//  XVimTaskRunner.m
//  XVim
//
//  Created by Ant on 02/09/2012.
//
//

#import "XVimTaskRunner.h"
#import "Logger.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED 1
#endif // __has_feature(objc_arc)


#if	ARC_ENABLED
#ifndef	AUTORELEASE
#define	AUTORELEASE(object)	(object)
#endif

#else

#ifndef	AUTORELEASE
#define	AUTORELEASE(object)	[(object) autorelease]
#endif
#endif

@interface XVimTaskRunner ()
+(NSString*)_createTempCommandFileWithContents:(NSString*)contents;
@end

@implementation XVimTaskRunner

+(BOOL)_waitForTaskToTerminate:(NSTask*)task
{
    NSUInteger waitCount = 0;
    BOOL taskKilled = NO;
    
    while ([task isRunning] && waitCount < 7) {
        waitCount++;
        [ NSThread sleepForTimeInterval:0.25 ];
    }
    if ([task isRunning]) {
        [task terminate];
        taskKilled = YES;
    }
    return taskKilled;
}

+(NSString*) runScript:(NSString*)scriptAndArgs withInput:(NSString*)input
{
    NSString* returnString = nil;
    NSTask *task = AUTORELEASE([[NSTask alloc] init]);
    if (!scriptAndArgs || [ scriptAndArgs length ] == 0) {
        return nil;
    }
    
    NSString* commandFile = [ self _createTempCommandFileWithContents:scriptAndArgs ];
    NSArray* arguments = [ NSArray arrayWithObjects:commandFile, nil];
    
    [task setLaunchPath:@"/bin/bash"];
    [task setArguments: arguments];
    
    NSPipe *outputPipe = [NSPipe pipe];
    [task setStandardOutput: outputPipe];
    NSPipe *inputPipe = [NSPipe pipe];
    [task setStandardInput:inputPipe];
    NSPipe *errorPipe = [NSPipe pipe];
    [task setStandardError:errorPipe];
    
    NSFileHandle *inputFile = nil;
    NSFileHandle *outputFile = [outputPipe fileHandleForReading];
    NSFileHandle *errorFile = [errorPipe fileHandleForReading];
    if (input!=nil)
    {
        inputFile = [inputPipe fileHandleForWriting];
    }
    
    NSMutableDictionary *environment = [NSMutableDictionary dictionaryWithDictionary:[task environment]];
	[environment setObject:@"YES" forKey:@"NSUnbufferedIO"];
	[task setEnvironment:environment];

    @try {
        [task launch];
        
        if ([ task isRunning])
        {
            int pid = [task processIdentifier];
            DEBUG_LOG(@"Running Task PID = %d, command = %@", pid, scriptAndArgs);
            
            if (input!=nil)
            {
                NSData *inputData = [ input dataUsingEncoding:NSUTF8StringEncoding ];
                [ inputFile writeData:inputData ];
                [ inputFile closeFile ];
            }
            
            NSData *outputData = [outputFile readDataToEndOfFile];
            BOOL taskKilled = [ self _waitForTaskToTerminate:task ] ;
            
            if (!taskKilled)
            {
                int exitStatus = [ task terminationStatus ];
                
                if ( exitStatus == 0 )
                {
                    returnString = AUTORELEASE([[NSString alloc] initWithData: outputData encoding: NSUTF8StringEncoding]);
                    DEBUG_LOG(@"Command returned status %d. PID = %d, Command = %@, Stdout = %@", exitStatus, pid, scriptAndArgs, returnString );
                    
                    
                }
                else
                {
                    NSData* errorData = [ errorFile readDataOfLength:1024 ];
                    NSString* errorString = AUTORELEASE([[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding]);
                    ERROR_LOG(@"Command returned non-zero status %d. PID = %d, Command = %@, Stderr = %@", exitStatus, pid, scriptAndArgs, errorString );
                }
            }
            else
            {
                ERROR_LOG(@"Had to kill task that refused to exit. PID = %d, Command = %@", pid, scriptAndArgs );
            }
        }
        else
        {
            ERROR_LOG(@"Task returned early. Exit code = %d, Command = %@", [task terminationStatus], scriptAndArgs );
        }
    }
    @catch (NSException *exception) {
        ERROR_LOG(@"Command %@ does not exist", [task launchPath]);
    }
    return returnString;

}

+(void) runScriptInTerminal:(NSString*)scriptAndArgs
{
    DEBUG_LOG(@"Going to run %@",scriptAndArgs);
    NSTask *task = AUTORELEASE([[NSTask alloc] init]);
    [task setLaunchPath:@"/usr/bin/open" ];

    NSString* script = [ NSString stringWithFormat:@"clear\n%@", scriptAndArgs ];
    NSString* tempCommandFile = [ self _createTempCommandFileWithContents:script ];
    if (tempCommandFile != nil)
    {
        [ task setArguments:[NSArray arrayWithObject:tempCommandFile]];
        @try {
            [ task launch ];
        }
        @catch (NSException *exception) {
            ERROR_LOG(@"Command %@ does not exist", [task launchPath]);
        }
    }
}


+(NSString*)_createTempCommandFileWithContents:(NSString*)contents
{
    static NSString* commandSuffix = @".command";
    NSString *tempFileTemplate = [@"xvim.XXXXXX" stringByAppendingString:commandSuffix];
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:tempFileTemplate];
    const char *tempFileTemplateCString = [tempFilePath fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemps(tempFileNameCString, (int)[commandSuffix length]);
    
    if (fileDescriptor == -1)
    {
        ERROR_LOG(@"Could not create temporary file for command");
        return nil;
    }
    NSFileHandle* fh = AUTORELEASE([[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:NO]);
    [ fh writeData:[ contents dataUsingEncoding:NSUTF8StringEncoding]];
    [ fh closeFile ];
    
    NSFileManager* fileManager = AUTORELEASE([[NSFileManager alloc] init]);
    
    NSString* filePath = [ fileManager stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);
    
    NSError* error = nil;
    if (![ fileManager setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0700] forKey:NSFilePosixPermissions] ofItemAtPath:filePath error:&error ])
    {
        ERROR_LOG(@"Could not set execute permissions on temporary file for command. Error code = %lu, reason = %@", [error code], [ error localizedDescription ]);
        return nil;
    }
    return filePath;
}

@end
