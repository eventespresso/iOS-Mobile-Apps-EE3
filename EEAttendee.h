//
//  EEAttendee.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kAttendeeAddressKey;
extern NSString* const kAttendeeAddress2Key;
extern NSString* const kAttendeeCommentsKey;
extern NSString* const kAttendeeCountryKey;
extern NSString* const kAttendeeEmailKey;
extern NSString* const kAttendeeFirstNameKey;
extern NSString* const kAttendeeIDKey;
extern NSString* const kAttendeeLastNameKey;
extern NSString* const kAttendeeNotesKey;
extern NSString* const kAttendeeRegKey;
extern NSString* const kAttendeePhoneKey;
extern NSString* const kAttendeeStateKey;
extern NSString* const kAttendeeZipKey;

@interface EEAttendee : EEJSONObject

@property (strong, nonatomic, readonly) NSString* address;
@property (strong, nonatomic, readonly) NSString* address2;
@property (strong, nonatomic, readonly) NSString* comments;
@property (strong, nonatomic, readonly) NSString* country;
@property (strong, nonatomic, readonly) NSString* email;
@property (strong, nonatomic, readonly) NSArray*  events;
@property (strong, nonatomic, readonly) NSString* firstname;
@property (strong, nonatomic, readonly) NSString* fullname;
@property (assign, nonatomic, readonly) NSNumber* ID;
@property (strong, nonatomic, readonly) NSString* lastname;
@property (strong, nonatomic, readonly) NSString* notes;
@property (strong, nonatomic, readonly) NSArray*  registrations;
@property (strong, nonatomic, readonly) NSString* phone;
@property (strong, nonatomic, readonly) NSString* state;
@property (strong, nonatomic, readonly) NSString* zip;

+ (id)attendeeWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
