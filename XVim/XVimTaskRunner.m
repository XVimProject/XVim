
//
//  XVimTaskRunner.m
//  XVim
//
//  Created by Ant on 02/09/2012.
//
//

#import "Logger.h"
#import "ProcessRunner.h"
#import "XVimTaskRunner.h"

#ifndef __has_feature
#define __has_feature(x) 0
#endif
#ifndef __has_extension
#define __has_extension __has_feature
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED 1
#endif // __has_feature(objc_arc)


#if     ARC_ENABLED
#ifndef AUTORELEASE
#define AUTORELEASE(object)     (object)
#endif

#else

#ifndef AUTORELEASE
#define AUTORELEASE(object)     [(object) autorelease]
#endif
#endif
#define SPACES_PER_TAB 8

char* spaces(NSUInteger num);
NSString* expandTabs(NSString* inStr);

@interface XVimTaskRunner ()
+(NSString*)_createTempCommandFileWithContents:(NSString*)contents;
@end

@implementation XVimTaskRunner

+(BOOL)_waitForTaskToTerminate:(NSTask*)task
{
    NSUInteger waitCount = 0;
    BOOL taskKilled = NO;

    while ([task isRunning] && waitCount < 7)
    {
        waitCount++;
        [ NSThread sleepForTimeInterval:0.25 ];
    }

    if ([task isRunning])
    {
        [task terminate];
        taskKilled = YES;
    }

    return taskKilled;
}



+(NSString*) runScript:(NSString*)scriptAndArgs withInput:(NSString*)input withTimeout:(NSTimeInterval)timeout
{
    // If we have no input, then this is a 'rangeless' bang command, and we will display the output
    // in the quickfix window, which should behave something like a terminal.
    BOOL usePty = (input==nil);
    
    NSMutableString* returnString = [NSMutableString string];
    __block BOOL outputReceived = NO;

    if (!scriptAndArgs || [ scriptAndArgs length ] == 0)
    {
        return nil;
    }

    ProcessRunner *task = [ProcessRunner task];
    task.launchPath  = @"/bin/bash";
    task.inputString = input;

    NSString* commandFile = [ self _createTempCommandFileWithContents:scriptAndArgs ];

    if (commandFile && [commandFile length])
    {
        TRACE_LOG(@"Input = %@", input);
        DEBUG_LOG(@"Created temporary command file %@ for command %@", commandFile, scriptAndArgs );
        if (input == nil)
        {
            [task.arguments addObject:commandFile];
        }
        else
        {
            [task.arguments addObjectsFromArray:[ NSArray arrayWithObjects:@"-l",commandFile, nil]];
        }
        
        task.receivedOutputString = ^void (NSString *output) {
            if (usePty)
            {
                [ output enumerateLinesUsingBlock:^(NSString *line, BOOL *stop) {
                    [ returnString appendFormat:@"%@\n", expandTabs(line) ];
                }];
            }
            else
            {
                [ returnString appendString:output ];
            }
            outputReceived = YES;
        };

        @try {
            [ task launchUsingPty:usePty ];
            [ task waitUntilExitWithTimeout:timeout ];
        }
        @catch (NSException *exception) {
            ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        }
        if (task.terminationStatus != 0)
        {
            ERROR_LOG(@"Command %@ returned with error code %ld", scriptAndArgs, task.terminationStatus );
            outputReceived = NO;
        }
    }
    else
    {
        ERROR_LOG(@"Could not create temporary command file for command %@", scriptAndArgs );
    }
    TRACE_LOG(@"Output = %@", returnString);

    return outputReceived ? returnString : nil;

}

+(NSString*)runScript:(NSString *)scriptName withInput:(NSString *)input
{
    return [ self runScript:scriptName withInput:input withTimeout:0 ];
}



+(NSString*)runScript:(NSString *)scriptName
{
    return [ self runScript:scriptName withInput:nil ];
}



+(NSString*)runScript:(NSString *)scriptName withTimeout:(NSTimeInterval)timeout
{
    return [ self runScript:scriptName withInput:nil withTimeout:timeout ];
}



+(void) runScriptInTerminal:(NSString*)scriptAndArgs
{
    DEBUG_LOG(@"Going to run %@",scriptAndArgs);
    NSTask *task     = AUTORELEASE([[NSTask alloc] init]);
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
            ERROR_LOG(@"Exception %@: %@", [exception name], [exception reason]);
        }
    }
}



+(NSString*)_createTempCommandFileWithContents:(NSString*)contents
{
    static NSString* commandSuffix = @".command";
    NSString *tempFileTemplate     = [@"xvim.XXXXXX" stringByAppendingString:commandSuffix];
    NSString *tempFilePath    = [NSTemporaryDirectory () stringByAppendingPathComponent:tempFileTemplate];
    const char *tempFileTemplateCString = [tempFilePath fileSystemRepresentation];
    char *tempFileNameCString = (char *)malloc(strlen(tempFileTemplateCString) + 1);
    strcpy(tempFileNameCString, tempFileTemplateCString);
    int fileDescriptor = mkstemps(tempFileNameCString, (int)[commandSuffix length]);

    if (fileDescriptor == -1)
    {
        ERROR_LOG(@"Could not create temporary file for command");
        return nil;
    }

    NSFileHandle* fh  = AUTORELEASE([[NSFileHandle alloc] initWithFileDescriptor:fileDescriptor closeOnDealloc:NO]);
    NSString* command = [ NSString stringWithFormat:@"%@\n", contents];
    [ fh writeData:[ command dataUsingEncoding:NSUTF8StringEncoding]];
    [ fh closeFile ];

    NSFileManager* fileManager = AUTORELEASE([[NSFileManager alloc] init]);

    NSString* filePath = [ fileManager stringWithFileSystemRepresentation:tempFileNameCString length:strlen(tempFileNameCString)];
    free(tempFileNameCString);

    NSError* error     = nil;

    if (![ fileManager setAttributes:[NSDictionary dictionaryWithObject:[NSNumber numberWithShort:0700] forKey:NSFilePosixPermissions] ofItemAtPath:filePath error:&error ])
    {
        ERROR_LOG(@"Could not set execute permissions on temporary file for command. Error code = %lu, reason = %@", [error code], [ error localizedDescription ]);
        return nil;
    }

    return filePath;
}



@end

#define MAX_TAB_WIDTH 100
static char SPACES[MAX_TAB_WIDTH+1];

char* spaces(NSUInteger num)
{
    if (*SPACES == 0)
    {
        memset(SPACES, ' ',MAX_TAB_WIDTH);
    }
    return SPACES+MAX_TAB_WIDTH-num;
}

NSString* expandTabs(NSString* inStr)
{
    NSMutableString* outStr = [ NSMutableString string ];
    NSArray* strs =[ inStr componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"\t"]];
    for (NSString* str in strs)
    {
        NSUInteger remainder = SPACES_PER_TAB - ( [ str length ] % SPACES_PER_TAB );
        [outStr appendFormat:@"%@%s", str, spaces(remainder)];
    }
    return outStr;
}
