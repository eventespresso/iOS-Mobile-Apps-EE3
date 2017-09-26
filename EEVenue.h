//
//  EEVenue.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kVenueAddressKey;
extern NSString* const kVenueAddress2Key;
extern NSString* const kVenueCityKey;
extern NSString* const kVenueCountryKey;
extern NSString* const kVenueIDKey;
extern NSString* const kVenueIdentifierKey;
extern NSString* const kVenueMetasKey;
extern NSString* const kVenueNameKey;
extern NSString* const kVenueStateKey;
extern NSString* const kVenueUserKey;
extern NSString* const kVenueZipKey;

@interface EEVenue : EEJSONObject

@property (strong, nonatomic) NSString*     address;
@property (strong, nonatomic) NSString*     address2;
@property (strong, nonatomic) NSString*     city;
@property (strong, nonatomic) NSString*     country;
@property (assign, nonatomic) NSNumber*     ID;
@property (strong, nonatomic) NSString*     identifier;
@property (strong, nonatomic) NSDictionary* metas;
@property (strong, nonatomic) NSString*     name;
@property (strong, nonatomic) NSString*     state;
@property (assign, nonatomic) NSInteger     user;
@property (strong, nonatomic) NSString*     zip;

+ (id)venueWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
