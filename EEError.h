//
//  EEError.h
//  EventEspressoHD
//
//  Event Espresso HD specific error domain and error codes.
//
//  Created by Michael A. Crawford on 9/30/12.
//  Copyright 2012 Crawford Design Engineering, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString* const EEErrorCodeKey;
extern NSString* const EEErrorIDKey;
extern NSString* const EEException;

extern NSString* const EEErrorDomain;
extern NSString* const EspressoAPIErrorDomain;

// Event Espresso HD specific error values are defined here.
typedef NS_ENUM(NSUInteger, ATErrorEnum)
{
    EEErrorNone = 0,
    EEErrorAudioPlayerAllocFailed,
    EEErrorBadHTTPStatusCode,
    EEErrorConnectionFailed,
    EEErrorInvalidCredentials,
    EEErrorInvalidEndpoint,
    EEErrorInvalidSessionKey,
    EEErrorMalformedJSONResponse,
    EEErrorNetworkNotAvailable,
    EEErrorNoAuthorization,
    EEErrorParserFailed,
    EEErrorRemoteHostNotReachable,
    EEErrorZeroLengthResponse
} ATError;
