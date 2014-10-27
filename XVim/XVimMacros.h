//
//  XVimMacros.h
//  XVim
//
//  Created by Anthony Dervish on 26/07/2014.
//
//

#ifndef XVim_XVimMacros_h
#define XVim_XVimMacros_h

#if __clang__
#define IGNORE_WARNING_PERFORM_SELECTOR_LEAK_PUSH _Pragma("clang diagnostic push") _Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"")
#define IGNORE_WARNING_PERFORM_SELECTOR_LEAK_POP _Pragma("clang diagnostic pop")
#else
#define IGNORE_WARNING_PERFORM_SELECTOR_LEAK_PUSH
#define IGNORE_WARNING_PERFORM_SELECTOR_LEAK_POP
#endif

#if __STDC_VERSION__ != 201112L
// C11 Static assertions are unavailable
#define _Static_assert(_assertion,_error)
#endif

// Until we start to work on the underflow errors, prefer to safely ignore attempts to underflow
#ifdef REASONABLY_HAPPY_THAT_UNDERFLOW_ERRORS_HAVE_BEEN_ADDRESSED
#define DECREMENT_ASSERT(_val,_dec) assert((_val)>=(_dec))
#define UNSIGNED_DECREMENT_UNCHECKED(_val,_dec) ((_val) - (_dec))
#else
#define DECREMENT_ASSERT(_val,_dec)
#define UNSIGNED_DECREMENT_UNCHECKED(_val,_dec) UNSIGNED_DECREMENT_CHECKED(_val,_dec)
#endif

// If C11 is available, include a static assert in the statement expression to check that _val is unsigned
#define UNSIGNED_DECREMENT_CHECKED(_val,_dec) \
(({_Static_assert( _Generic((_val+1l), NSUInteger:1, default:0), "_val must be unsigned"); \
DECREMENT_ASSERT(_val,_dec); true;}), \
(((_val) >= (_dec)) ? ((_val) - (_dec)) : 0))

#ifdef DEBUG
#define UNSIGNED_DECREMENT(_val,_dec) UNSIGNED_DECREMENT_CHECKED(_val,_dec)
#else
#define UNSIGNED_DECREMENT(_val,_dec) UNSIGNED_DECREMENT_UNCHECKED(_val,_dec)
#endif

#endif
