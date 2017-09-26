//
//  EEAttendeesRequest.h
//  EventEspressoHD
//
//  Espresso-API request for attendee information.
//
//  Created by Michael A. Crawford on 10/18/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONRequest.h"

@interface EEAttendeesRequest : EEJSONRequest

@property (strong, nonatomic, readonly) NSArray* returnedAttendees;

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