//
//  EEEventsRequest.h
//  EventEspressoHD
//
//  Espresso-API request for event information.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONRequest.h"

@interface EEEventsRequest : EEJSONRequest

@property (strong, nonatomic, readonly) NSArray* returnedEvents;

- (id)initWithQueryParams:(NSString *)params
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
               completion:(EERestAPICompletion)completion;

- (id)initWithQueryParams:(NSString *)params
               sessionKey:(NSString *)sessionKey
                      URL:(NSURL *)URL
         startImmediately:(BOOL)startImmediately
               completion:(EERestAPICompletion)completion;

+ (id)requestWithQueryParams:(NSString *)params
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
                  completion:(EERestAPICompletion)completion;

- (void)start;

@end
