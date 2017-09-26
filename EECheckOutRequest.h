//
//  EECheckOutRequest.h
//  EventEspressoHD
//
//  Espresso-API request for checking-out an attendee via a registration ID.
//
//  Created by Michael A. Crawford on 12/20/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONRequest.h"

@interface EECheckOutRequest : EEJSONRequest

@property (assign, nonatomic) NSUInteger quantity;
@property (strong, nonatomic, readonly) NSMutableArray* returnedRegistrations;

- (id)initWithRegistrationID:(NSNumber *)registrationID
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
                  completion:(EERestAPICompletion)completion;

- (id)initWithRegistrationID:(NSNumber *)registrationID
                    quantity:(NSUInteger)quantity
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
            startImmediately:(BOOL)startImmediately
                  completion:(EERestAPICompletion)completion;

+ (id)requestWithRegistrationID:(NSNumber *)registrationID
                       quantity:(NSUInteger)quantity
                     sessionKey:(NSString *)sessionKey
                            URL:(NSURL *)URL
                     completion:(EERestAPICompletion)completion;

- (void)start;

@end
