//
//  Logger.h
//  XVim
//
//  Created by Shuichiro Suzuki on 12/25/11.
//  Copyright 2011 JugglerShu.Net. All rights reserved.
//

#import <Foundation/Foundation.h>


#if defined DEBUG && !defined LOGGER_DISABLE_DEBUG  && !defined LOGGER_DISABLE_ALL
#define TRACE_LOG(fmt,...) [Logger logWithLevel:LogTrace format:@"%50s%5d: " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__];
#define DEBUG_LOG(fmt,...) [Logger logWithLevel:LogDebug format:@"%50s%5d: " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__];
#else
#define TRACE_LOG(fmt,...)
#define DEBUG_LOG(fmt,...)
#endif

#if defined DEBUG && !defined LOGGER_DISABLE_ALL
#define ERROR_LOG(fmt,...) [Logger logWithLevel:LogError format:@"%50s%5d: " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]
#define FATAL_LOG(fmt,...) [Logger logWithLevel:LogFatal format:@"%50s%5d: " fmt, __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__]
#else
#define ERROR_LOG(fmt,...) 
#define FATAL_LOG(fmt,...)
#endif

#define REGISTER_CLASS_FOR_METHOD_TRACING(cls) [Logger registerTracing:cls]
typedef enum LogLevel_t{
    LogTrace,
    LogDebug,
    LogError,
    LogFatal
} LogLevel;

@interface Logger : NSObject

@property LogLevel level;
@property(strong) NSString* name;

+ (void) logWithLevel:(LogLevel)level format:(NSString*)format, ...;
+ (void) registerTracing:(NSString*)name;
+ (Logger*) defaultLogger;

- (id) initWithName:(NSString*)name; // "Root.MyPackage.MyComponent"
- (id) initWithName:(NSString *)n level:(LogLevel)l;

- (void) logWithLevel:(LogLevel)level format:(NSString*)format, ...;
- (void) setLogFile:(NSString*)path;

// Support Functions
+ (void) logStackTrace:(NSException*)ex;
+ (void) traceMethodList:(NSString*)class;
+ (void) logAvailableClasses:(LogLevel)level;
+ (void) traceViewInfo:(NSView*)obj subView:(BOOL)sub;
+ (void)traceView:(NSView*)view depth:(NSUInteger)depth;
+ (void) traceMenu:(NSMenu*)menu;
@end
