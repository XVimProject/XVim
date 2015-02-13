
// define some LLVM3 macros if the code is compiled with a different compiler
// (ie LLVMGCC42)
#ifndef __has_feature
#define __has_feature(x) 0
#endif

#ifndef __has_extension
#define __has_extension __has_feature // Compatibility with pre-3.0 compilers.
#endif

#if __has_feature(objc_arc) && __clang_major__ >= 3
#define ARC_ENABLED 1
#endif
// __has_feature(objc_arc)

#if ARC_ENABLED
/*
 *
 *
 *================================================================================================*/
#pragma mark - ARC
/*==================================================================================================
 */

#ifndef RETAIN
#define RETAIN(object) (object)
#endif


#ifndef RELEASE
#define RELEASE(object)
#endif

#ifndef AUTORELEASE
#define AUTORELEASE(object) (object)
#endif


#ifndef SUPER_DEALLOC
#define SUPER_DEALLOC
#endif

#define BRIDGE(x) ((__bridge void *)x)

#ifndef DISPATCH_RELEASE
#define DISPATCH_RELEASE(object)
#endif
/*
 *
 *
 *================================================================================================*/
#pragma mark - NO ARC
/*==================================================================================================
 */

#else // Not ARC_ENABLED

#define BRIDGE(x) x

#ifndef RETAIN
#define RETAIN(object) [(object)retain]
#endif

#ifndef RELEASE
#define RELEASE(object) [(object)release]
#endif

#ifndef AUTORELEASE
#define AUTORELEASE(object) [(object)autorelease]
#endif

#ifndef SUPER_DEALLOC
#define SUPER_DEALLOC [super dealloc]
#endif

#ifndef DISPATCH_RELEASE
#define DISPATCH_RELEASE(object) dispatch_release(object)
#endif

#endif

// not using clang LLVM compiler, or LLVM version is not 3.x
#if !defined(__clang__) || __clang_major__ < 3 || !defined(ARC_ENABLED)

#ifndef __bridge
#define __bridge
#endif
#ifndef __bridge_retained
#define __bridge_retained
#endif
#ifndef __bridge_transfer
#define __bridge_transfer
#endif
#ifndef __autoreleasing
#define __autoreleasing
#endif
#ifndef __strong
#define __strong
#endif
#ifndef __weak
#define __weak
#endif
#ifndef __unsafe_unretained
#define __unsafe_unretained
#endif

#endif // __clang_major__ < 3
