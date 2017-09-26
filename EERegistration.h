//
//  EERegistration.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 10/27/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kRegistrationAttendeeKey;
extern NSString* const kRegistrationCodeKey;
extern NSString* const kRegistrationDateKey;
extern NSString* const kRegistrationDatetimeKey;
extern NSString* const kRegistrationEventKey;
extern NSString* const kRegistrationFinalPriceKey;
extern NSString* const kRegistrationIDKey;
extern NSString* const kRegistrationIsCheckedInKey;
extern NSString* const kRegistrationIsGoingKey;
extern NSString* const kRegistrationIsGroupRegKey;
extern NSString* const kRegistrationIsPrimaryKey;
extern NSString* const kRegistrationPriceKey;
extern NSString* const kRegistrationStatusKey;
extern NSString* const kRegistrationTransactionKey;
extern NSString* const kRegistrationURLLinkKey;

@class EEAttendee, EEDateTime, EEEvent, EEPrice, EETransaction;

@interface EERegistration : EEJSONObject

@property (strong, readonly) EEAttendee*            attendee;
@property (strong, readonly) NSString*              attendeeLastName;
@property (strong, readonly, nonatomic) NSString*   code;
@property (strong, readonly, nonatomic) NSString*   date;
@property (strong, readonly) EEDateTime*            datetime;
@property (strong, readonly) EEEvent*               event;
@property (strong, readonly) NSDecimalNumber*       finalPrice;
@property (strong, readonly, nonatomic) NSNumber*   ID;
@property (assign, readonly, nonatomic) BOOL        isCheckedIn;
@property (assign, readonly, nonatomic) BOOL        isGoing;
@property (assign, readonly, nonatomic) BOOL        isGroupRegistration;
@property (assign, readonly, nonatomic) BOOL        isPrimary;
@property (strong, readonly) EEPrice*               price;
@property (strong, readonly, nonatomic) NSString*   status;
@property (strong, readonly) EETransaction*         transaction;
@property (strong, readonly, nonatomic) NSString*   urlLink;

// Array of associated registrations belonging to the same attendee.ID
@property (strong, nonatomic) NSMutableArray* additionalTickets;
@property (assign, readonly, nonatomic) NSUInteger ticketsPurchased;
@property (assign, readonly, nonatomic) NSUInteger ticketsRedeemed;

+ (id)registrationWithJSONDictionary:(NSMutableDictionary *)jsonDict;

- (NSUInteger)replaceMatchingRegistration:(EERegistration *)registration;

@end
