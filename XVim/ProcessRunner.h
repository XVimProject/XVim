// Replacement for NSTask
//  Based on Taskit Written by Alex Gordon on 09/09/2011.
//  Licensed under the WTFPL: http://sam.zoy.org/wtfpl/

#import <Foundation/Foundation.h>

typedef enum {
    
    TaskitWaitFor_Exit = 1,
    TaskitWaitFor_Output = 1 << 1,
    
} TaskitWaitMaskComponent;
typedef unsigned TaskitWaitMask;

@interface ProcessRunner : NSObject
{
    BOOL hasLaunched;
    
    NSString *launchPath;
    NSMutableArray *arguments;
    NSMutableDictionary *environment;
    NSString *workingDirectory;
    
    NSData *input;
    NSString *inputString;
    NSString* inputPath; // Optional alternative to inputString
    
    NSFileHandle *inFileHandle;
    NSFileHandle *processOutputFileHandleRead;
    NSFileHandle *processOutputFileHandleWrite;
    NSPipe *processInputPipe;
    NSPipe *processOutputPipe;
    
    pid_t pid;
    int waitpid_status;
    BOOL isRunning;
    
    void (^receivedOutputData)(NSData *output);
    void (^receivedOutputString)(NSString *outputString);
    
    NSMutableData *outputBuffer;
    NSMutableData *errorBuffer;
    
    BOOL hasFinishedReadingOutput;
    BOOL hasRetainedForOutput;
    
    NSTimeInterval timeoutIfNothing;
    NSTimeInterval timeoutSinceOutput;
    
    NSInteger priority;
    NSUInteger outputColWidth ;
}

+ (id)task;
- (id)init;

#pragma mark Setup

@property (copy) NSString *launchPath;
@property (readonly) NSMutableArray *arguments;
@property (readonly) NSMutableDictionary *environment;
@property (copy) NSString *workingDirectory;

@property (copy) NSData *input;
@property (copy) NSString *inputString;
@property (copy) NSString *inputPath;

@property (assign) NSUInteger outputColWidth; // Only for PTY mode

@property (assign) NSInteger priority;

- (void)populateWithCurrentEnvironment;

//TODO: @property (assign) BOOL usesAuthorization;

#pragma mark Concurrency
@property (copy) void (^receivedOutputData)(NSData *output);
@property (copy) void (^receivedOutputString)(NSString *outputString);

#pragma mark Timeouts

// The amount of time to wait if nothing has been read yet
@property (assign) NSTimeInterval timeoutIfNothing;

// The amount of time to wait for stderr if stdout HAS been read
@property (assign) NSTimeInterval timeoutSinceOutput;


#pragma mark Status
- (NSInteger)processIdentifier;
- (NSInteger)terminationStatus;
- (NSTaskTerminationReason)terminationReason;
- (NSInteger)terminationSignal;


#pragma mark Control
- (BOOL)launchUsingPty:(BOOL)usePty;

- (void)interrupt; // Not always possible. Sends SIGINT.
- (void)terminate; // Not always possible. Sends SIGTERM.
- (void)kill;

- (BOOL)suspend;
- (BOOL)resume;


- (BOOL)isRunning;
- (void)reapOnExit;

#pragma mark Blocking methods
- (void)waitUntilExit;
- (BOOL)waitUntilExitWithTimeout:(NSTimeInterval)timeout;

- (BOOL)waitForIntoOutputData:(NSMutableData *)output ;
- (BOOL)waitForOutputData:(NSData **)output errorData:(NSData **)error;
- (void)waitForOutputString:(NSString **)output errorString:(NSString **)error;

- (NSData *)waitForOutput;
- (NSString *)waitForOutputString;

@end
