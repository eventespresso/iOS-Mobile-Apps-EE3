/*
 *  MCLog.h
 *  MCUtilities
 *
 *  Created by Michael A. Crawford on 8/13/09.
 *  Copyright 2009 Crawford Design Engineering, LLC. All rights reserved.
 *
 *  Only invokes NSLog on a Debug or Release configuration.  A Distribution
 *  build willcontain no calls to NSLog.  Context version of logging function
 *  includes information about where the log statement was generated in the
 *  source code.
 */

#ifndef __MC_LOG_H__
#define __MC_LOG_H__

/* TODO: Add a basename(__FILE__) function */

#ifdef DISTRIBUTION
#    define MCCtxLog(s, ...) do {} while (0)
#    define MCLog(...) do {} while (0)
#    define MCLogFuncEntry() do {} while (0)
#else
#    define MCCtxLog(s, ...) NSLog((@"%s %s:%d " s), __PRETTY_FUNCTION__, __FILE__, __LINE__, ##__VA_ARGS__)
#    define MCLog(...) NSLog(__VA_ARGS__)
#    define MCLogFuncEntry() NSLog((@"%s"), __PRETTY_FUNCTION__)
#endif

#ifdef DEBUG
#define MCLogDebug(...) NSLog(__VA_ARGS__)
#else
#define MCLogDebug(...) do {} while (0)
#endif

#ifdef DEBUG
#define DLog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#define ALog(...) {NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__]);[[NSAssertionHandler currentHandler] handleFailureInFunction:@(__PRETTY_FUNCTION__) file:@(__FILE__) lineNumber:__LINE__ description:__VA_ARGS__];}
#else
#define DLog(...) do { } while (0)
#ifndef NS_BLOCK_ASSERTIONS
#define NS_BLOCK_ASSERTIONS
#endif
#define ALog(...) NSLog(@"%s(%p) %@", __PRETTY_FUNCTION__, self, [NSString stringWithFormat:__VA_ARGS__])
#endif

#define ZAssert(condition, ...) do { if (!(condition)) { ALog(__VA_ARGS__); }} while(0)

#endif /* __MC_LOG_H__ */
