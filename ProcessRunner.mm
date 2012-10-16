
// Replacement for NSTask
//  Based on Taskit Written by Alex Gordon on 09/09/2011.
//  Licensed under the WTFPL: http://sam.zoy.org/wtfpl/

#import "ProcessRunner.h"
#include <sys/resource.h>
#include <unistd.h>
#include <util.h>
#include <sys/ioctl.h>


@interface ProcessRunner ()
{
    NSString* _ttyName;
}

@end

@implementation ProcessRunner

@synthesize launchPath;
@synthesize arguments;
@synthesize environment;
@synthesize workingDirectory;

@synthesize input;
@synthesize inputString;
@synthesize inputPath;
//TODO: @synthesize usesAuthorization;

@synthesize receivedOutputData;
@synthesize receivedOutputString;
//TODO: @synthesize processExited;

@synthesize timeoutIfNothing;

// The amount of time to wait for stdout if stderr HAS been read
@synthesize timeoutSinceOutput;

@synthesize priority;


+ (id)task {
    return [[[[self class] alloc] init] autorelease];
}



- (id)init {
    self = [super init];

    if (!self)
        return nil;

    arguments   = [[NSMutableArray alloc] init];
    environment = [[NSMutableDictionary alloc] init];

    self.workingDirectory = [[NSFileManager defaultManager] currentDirectoryPath];

    priority = NSIntegerMax;

    return self;
}



static const char*
CHAllocateCopyString(NSString *str) {
    char *newString = NULL;
    const char* __strong originalString = [str fileSystemRepresentation];

    if (originalString)
    {
        newString = strdup(originalString);
    }

    return newString;
}



- (void)populateWithCurrentEnvironment {
    [environment addEntriesFromDictionary:[[NSProcessInfo processInfo] environment]];
}



- (BOOL)launchUsingPty:(BOOL)usePty
{

    if ( launchPath == nil || [ launchPath length ] == 0)
    {
        return NO;
    }

    self.launchPath = [launchPath stringByStandardizingPath];

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:launchPath])
    {
        [ NSException raise:@"ProcessRunnerCommandIsNotExecutable" format:@"%@ is not executable", launchPath ];
    }

    [arguments insertObject:launchPath atIndex:0];

    if ([arguments count] + [environment count] + 2 > ARG_MAX)
    {
        [ NSException raise:@"ProcessRunnerTooManyArguments"
                     format:@"Number of arguments (%lu) is greater than ARG_MAX (%u)", [arguments count] + [environment count] + 2, ARG_MAX ];
    }

// Set up
    // Set up launch path, arguments, environment and working directory
    const char* executablePath = CHAllocateCopyString(launchPath);

    if (!executablePath)
    {
        [ NSException raise:@"ProcessRunnerMemoryError"
                     format:@"Could not allocate memory for executable path string"];
    }

    const char* workingDirectoryPath = CHAllocateCopyString(workingDirectory);

    if (!workingDirectoryPath)
    {
        [ NSException raise:@"ProcessRunnerMemoryError"
                     format:@"Could not allocate memory for executable path string"];
    }

    const char** argumentsArray = (const char**)calloc([arguments count] + 1, sizeof(char*));
    NSInteger argCounter = 0;

    for (NSString *argument in arguments)
    {
        argumentsArray[argCounter] = CHAllocateCopyString(argument);

        if (argumentsArray[argCounter])
            argCounter++;
    }
    
    
    // Build Environment
    // -----------------

    const char **environmentArray = (const char**)calloc([environment count] + 1, sizeof(char*));
    NSInteger envCounter = 0;

    for (NSString *environmentKey in environment)
    {
        NSString *environmentValue = [environment valueForKey:environmentKey];

        if (![environmentKey length] || !environmentValue)
            continue;

        NSString *environmentPair = [NSString stringWithFormat:@"%@=%@", environmentKey, environmentValue];

        environmentArray[envCounter] = CHAllocateCopyString(environmentPair);
        envCounter++;
    }

    int masterfd, slavefd;
    char devname[64];

    // Create File Handles
    // -------------------
    
    if (usePty)
    {
        struct winsize ptySize = { 999, 100, 0, 0 };
        if (openpty(&masterfd, &slavefd, devname, NULL, &ptySize) == -1)
        {
            [NSException raise:@"OpenPtyErrorException"
                        format:@"%s", strerror(errno)];
        }

        _ttyName = [[NSString alloc] initWithCString:devname encoding:NSASCIIStringEncoding ];

        setsid();
        ioctl(slavefd, TIOCSCTTY, NULL);
        
        processOutputFileHandleRead = [[ NSFileHandle alloc ] initWithFileDescriptor:masterfd ];
    }
    else
    {
        processOutputPipe = [ NSPipe new ];
        processOutputFileHandleWrite = [ processOutputPipe fileHandleForWriting ];
        processOutputFileHandleRead = [ processOutputPipe fileHandleForReading ];
    }
    processInputPipe = [ NSPipe new ];
    NSFileHandle* processInputFileHandleWrite = [ processInputPipe fileHandleForWriting ];
    NSFileHandle* processInputFileHandleRead = [ processInputPipe fileHandleForReading ];
    
    if (receivedOutputData || receivedOutputString)
    {

        CFRetain(self);
        hasRetainedForOutput = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector( asyncFileHandleReadCompletion: )
                                                     name:NSFileHandleReadToEndOfFileCompletionNotification
                                                   object:processOutputFileHandleRead ];

        [processOutputFileHandleRead readToEndOfFileInBackgroundAndNotifyForModes:
         [NSArray arrayWithObjects:NSDefaultRunLoopMode, @"taskitwait", nil]];
    }
    
// Execution
    pid_t p = fork();

    if (p == 0)
    {
        //
        // CHILD
        // -----
        //

        close([processInputFileHandleWrite fileDescriptor]);
        dup2([processInputFileHandleRead fileDescriptor], STDIN_FILENO);
        close([processInputFileHandleRead fileDescriptor]);
        
        if (usePty)
        {
            close(masterfd);
            dup2(slavefd, STDOUT_FILENO);
            dup2(slavefd, STDERR_FILENO);
            close(slavefd);
        }
        else
        {
            close([processOutputFileHandleRead fileDescriptor]);
            dup2([processOutputFileHandleWrite fileDescriptor], STDOUT_FILENO);
            close([processOutputFileHandleWrite fileDescriptor]);
            
            close(STDERR_FILENO);
        }

        chdir(workingDirectoryPath);

        //sleep(1);

        int oldpriority = getpriority(PRIO_PROCESS, (id_t)getpid());

        if (priority < 20 && priority > -20 && priority > oldpriority)
            setpriority(PRIO_PROCESS, (id_t)getpid(), (int)priority);

        execve(executablePath, (char * const *)argumentsArray, (char * const *)environmentArray);

        // execve failed for some reason, try to quit gracefullyish
        _exit(0);

        // Uh oh, we shouldn't be here
        abort();
        return NO;
    }
    else
    if (p == -1)
    {
        [ NSException raise:@"ProcessRunnerForkFailed"
                     format:@"Could not fork process. Error %s", strerror(errno)];
    }
    else
    {
        //
        // PARENT
        // ------
        //
        pid = p;

        if (usePty)
        {
            close(slavefd);
        }
        else
        {
            [ processInputFileHandleRead closeFile ];
            [ processOutputFileHandleWrite closeFile ];
        }
    }

    isRunning = YES;

    // Clean up
    // --------
    
    free((void *)executablePath);
    free((void *)workingDirectoryPath);

    for (size_t i = 0; i < argCounter; i++)
        free((void *)argumentsArray[i]);

    free(argumentsArray);

    for (size_t i = 0; i < envCounter; i++)
        free((void *)environmentArray[i]);

    free(environmentArray);

// Writing
    // We want to open stdin on p and write our input
    NSData *inputData = input ? : [inputString dataUsingEncoding:NSUTF8StringEncoding];

    if (inputData)
    {
        [processInputFileHandleWrite writeData:inputData];
    }

    if (usePty)
    {
        close(masterfd);
    }
    else
    {
        [ processInputFileHandleWrite closeFile ];
    }

    return YES;
}



- (BOOL)isRunning {

    if (!isRunning)
    {
        return NO;
    }

    waitpid_status = 0;
    pid_t wp = waitpid(pid, &waitpid_status, WNOHANG);

    if (!wp)
    {
        return YES;
    }

    // if wp == -1, fail safely: act as though the process exited normally
    if (wp == -1)
        waitpid_status = 0;

    isRunning = NO;
    return isRunning;
}



- (NSInteger)processIdentifier {
    return pid;
}



- (NSInteger)terminationStatus {
    if (WIFEXITED(waitpid_status))
        return WEXITSTATUS(waitpid_status);

    return 1; // lie
}



- (NSTaskTerminationReason)terminationReason {
    if (WIFEXITED(waitpid_status))
        return NSTaskTerminationReasonExit;

    if (WIFSIGNALED(waitpid_status))
        return NSTaskTerminationReasonUncaughtSignal;

    return 0;
}



- (NSInteger)terminationSignal {
    if (WIFSIGNALED(waitpid_status))
        return WTERMSIG(waitpid_status);

    return 0;
}



- (void)interrupt // Not always possible. Sends SIGINT.
{
    if ([self isRunning])
        kill(pid, SIGINT);
}



- (void)terminate // Not always possible. Sends SIGTERM.
{
    if ([self isRunning])
    {
        kill(pid, SIGTERM);
        [self isRunning];
    }
}



- (void)kill
{
    [self terminate];

    if ([self isRunning])
    {
        kill(pid, SIGKILL);
        [self isRunning];
    }
}



- (BOOL)suspend
{
    if ([self isRunning])
        kill(pid, SIGSTOP);

    return [self isRunning];
}



- (BOOL)resume
{
    if ([self isRunning])
        kill(pid, SIGCONT);

    return [self isRunning];
}



#pragma mark Blocking methods

- (void)reapOnExit {
    if (pid > 0 && [self isRunning])
    {
        dispatch_source_t source = dispatch_source_create(DISPATCH_SOURCE_TYPE_PROC, (uintptr_t)pid, DISPATCH_PROC_EXIT, dispatch_get_main_queue());
        CFRetain(self);

        if (source)
        {
            dispatch_source_set_event_handler(source, ^{
                                                  CFRelease(self);
                                                  [self isRunning];
                                                  dispatch_source_cancel(source);
                                                  dispatch_release(source);
                                              }
                                              );
            dispatch_resume(source);
        }
    }
}



- (void)waitUntilExit {

    NSRunLoop *runloop   = [NSRunLoop currentRunLoop];
    NSTimeInterval delay = 0.01;

    while ([self isRunning])
    {

        [runloop runMode:@"taskitwait" beforeDate:[NSDate dateWithTimeIntervalSinceNow:delay]];

        delay *= 1.5;

        if (delay >= 1.0)
            delay = 1.0;
    }
}



- (BOOL)waitUntilExitWithTimeout:(NSTimeInterval)timeout {

    BOOL hitTimeout = NO;

    if (timeout != 0 )
    {
        NSRunLoop *runloop       = [NSRunLoop currentRunLoop];
        NSTimeInterval delay     = 0.01;

        NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];

        while ([self isRunning])
        {

            NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];

            if (timeout > 0 && currentTime - startTime > timeout)
            {
                hitTimeout = YES;
                break;
            }

            [runloop runMode:@"taskitwait" beforeDate:[NSDate dateWithTimeIntervalSinceNow:delay]];

            delay *= 1.5;

            if (delay >= 1.0)
                delay = 1.0;
        }

        if (hitTimeout)
            [self kill];
    }
    else
    {
        [ self waitUntilExit ];
    }

    return hitTimeout;
}



- (NSData *)waitForOutput {

    NSData *ret = nil;
    [self waitForOutputData:&ret errorData:NULL];

    return ret;
}



- (NSString *)waitForOutputString {

    NSString *ret = nil;
    [self waitForOutputString:&ret errorString:NULL];

    return ret;
}



// Want to either wait for it to exit, or for it to EOF
- (NSData *)waitForError {

    NSData *ret = nil;
    [self waitForOutputData:NULL errorData:&ret];

    return ret;
}



- (NSString *)waitForErrorString {

    NSString *ret = nil;
    [self waitForOutputString:NULL errorString:&ret];

    return ret;
}



- (void)asyncFileHandleReadCompletion:(NSNotification *)notif {

    NSData *data = [[notif userInfo] valueForKey:NSFileHandleNotificationDataItem];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:[notif name] object:[notif object]];

    if ([[notif object] isEqual:processOutputFileHandleRead])
    {

        hasFinishedReadingOutput = YES;
        [processOutputFileHandleRead closeFile];

        if (receivedOutputData)
            receivedOutputData(data);

        if (receivedOutputString)
        {
            NSString* outputString = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
            receivedOutputString(outputString);
        }

        if (hasRetainedForOutput)
        {
            CFRelease(self);
            hasRetainedForOutput = NO;
        }
    }
}




- (BOOL)waitForOutputData:(NSData **)output errorData:(NSData **)error {

    NSMutableData *outdata = [NSMutableData data];
    NSMutableData *errdata = [NSMutableData data];

    BOOL hadWhoopsie = [self waitForIntoOutputData:outdata ];

    if (output)
        *output = outdata;

    if (error)
        *error = errdata;

    return hadWhoopsie;
}



- (BOOL)waitForIntoOutputData:(NSMutableData *)outdata
{

    if (receivedOutputData || receivedOutputString )
        @throw [[NSException alloc] initWithName : @"TaskitAsyncSyncCombination" reason : @
                "-waitForOutputData:errorData: called when async output is in use. These two features are mutually exclusive!" userInfo :[NSDictionary dictionary]];

    if (![self isRunning])
    {
        return YES;
    }

    int outfd    = [processOutputFileHandleRead fileDescriptor];

    int outflags = fcntl(outfd, F_GETFL, 0);
    fcntl(outfd, F_SETFL, outflags | O_NONBLOCK);

#define TASKIT_BUFLEN 200

    char outbuf[TASKIT_BUFLEN];

    BOOL hasFinishedOutput  = NO;
    BOOL outputHadAWhoopsie = NO;

    while (1)
    {
        if (!hasFinishedOutput)
        {
            ssize_t outread = read(outfd, &outbuf, TASKIT_BUFLEN);
            const volatile int outerrno = errno;

            if (outread >= 1)
            {
                [outdata appendBytes:outbuf length:(NSUInteger)outread];
            }
            else
            if (outread == 0)
            {
                hasFinishedOutput = YES;
            }
            else
            {
                if (outerrno != EAGAIN)
                {
                    hasFinishedOutput  = YES;
                    outputHadAWhoopsie = YES;
                }
            }
        }

        if (hasFinishedOutput )
        {
            break;
        }
    }

    return !outputHadAWhoopsie ;
}



- (void)waitForOutputString:(NSString **)output errorString:(NSString **)error {
    NSData *outputData = nil;
    NSData *errorData  = nil;

    [self waitForOutputData:output ? &outputData : NULL errorData:error ? &errorData : NULL];

    if (outputData)
        *output = [[[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding] autorelease];

    if (errorData)
        *error = [[[NSString alloc] initWithData:errorData encoding:NSUTF8StringEncoding] autorelease];
}



#pragma mark Goodbye!

- (void)dealloc {

    //NSLog(@"Deallocing %@", launchPath);

    [ _ttyName release ];

    [launchPath release];
    [arguments release];
    [environment release];
    [workingDirectory release];

    [input release];
    [inputString release];
    [inputPath release];

    if (processOutputPipe)
    {
        // Releasing the pipe releases the file handles
        [ processOutputPipe release ];
    }
    else
    {
        [processOutputFileHandleRead release];
        [processOutputFileHandleWrite release];
    }
    [processInputPipe release];
    [inFileHandle release];

    [receivedOutputData release];
    [receivedOutputString release];

    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [super dealloc];
}



@end
