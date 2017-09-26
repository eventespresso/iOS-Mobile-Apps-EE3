//
//  EEJSONRequest.h
//  EventEspressoHD
//
//  This class/module hold common implementation details for all REST API request
//  types carying a JSON payload for the request and response.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EERestAPIRequest.h"

extern NSString* const EEJSONAttendeesKey;
extern NSString* const EEJSONBodyKey;
extern NSString* const EEJSONEventsKey;
extern NSString* const EEJSONRegistrationsKey;
extern NSString* const EEJSONSessionKeyKey;
extern NSString* const EEJSONStatusKey;
extern NSString* const EEJSONStatusCodeKey;

@interface EEJSONRequest : EERestAPIRequest

@property (strong, nonatomic, readonly) NSString* endpoint;
@property (strong, nonatomic, readonly) NSString* sessionKey;
@property (strong, nonatomic) id results;   // either a dict or an array

- (id)initWithEndpoint:(NSString *)endpoint
            sessionKey:(NSString *)sessionKey
                   URL:(NSURL *)URL
            completion:(EERestAPICompletion)completion;

- (id)initWithEndpoint:(NSString *)endpoint
            sessionKey:(NSString *)sessionKey
                   URL:(NSURL *)URL
      startImmediately:(BOOL)startImmediately
            completion:(EERestAPICompletion)completion;

+ (id)requestWithEndpoint:(NSString *)endpoint
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion;

- (void)start;
- (NSError *)validateResponse;

@end
