//
//  EECheckInRequest.h
//  EventEspressoHD
//
//  Espresso-API request for checking-in an attendee via a registration ID.
//
//  Created by Michael A. Crawford on 12/20/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEJSONRequest.h"

@class EERegistration;

@interface EECheckInRequest : EEJSONRequest

@property (assign, nonatomic) BOOL ignorePaymentStatus;
@property (assign, nonatomic) NSUInteger quantity;
@property (strong, nonatomic, readonly) NSMutableArray* returnedRegistrations;

- (id)initWithRegistrationID:(NSNumber *)registrationID
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
                  completion:(EERestAPICompletion)completion;

- (id)initWithRegistrationID:(NSNumber *)registrationID
                    quantity:(NSUInteger)quantity
         ignorePaymentStatus:(BOOL)ignorePaymentStatus
                  sessionKey:(NSString *)sessionKey
                         URL:(NSURL *)URL
            startImmediately:(BOOL)startImmediately
                  completion:(EERestAPICompletion)completion;

+ (id)requestWithRegistrationID:(NSNumber *)registrationID
                       quantity:(NSUInteger)quantity
            ignorePaymentStatus:(BOOL)ignorePaymentStatus
                     sessionKey:(NSString *)sessionKey
                            URL:(NSURL *)URL
                     completion:(EERestAPICompletion)completion;

- (void)start;

@end
