//
//  EEVenue.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEVenue.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kVenueAddress2Key   = @"address2";
NSString* const kVenueAddressKey    = @"address";
NSString* const kVenueCityKey       = @"city";
NSString* const kVenueCountryKey    = @"country";
NSString* const kVenueIDKey         = @"id";
NSString* const kVenueIdentifierKey = @"identifier";
NSString* const kVenueMetasKey      = @"metas";
NSString* const kVenueNameKey       = @"name";
NSString* const kVenueStateKey      = @"state";
NSString* const kVenueUserKey       = @"user";
NSString* const kVenueZipKey        = @"zip";

@implementation EEVenue

#pragma mark - Initialization

+ (id)venueWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kVenueAddress2Key, kVenueAddressKey, kVenueCityKey,
        kVenueCountryKey, kVenueIdentifierKey, kVenueMetasKey, kVenueNameKey,
        kVenueStateKey, kVenueZipKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return self.name;
}

#pragma mark - Properties

- (NSString *)address
{
    return self.jsonDict[kVenueAddressKey];
}

- (NSString *)address2
{
    return self.jsonDict[kVenueAddress2Key];
}

- (NSString *)city
{
    return self.jsonDict[kVenueCityKey];
}

- (NSString *)country
{
    return self.jsonDict[kVenueCountryKey];
}

- (NSNumber *)ID
{
    return self.jsonDict[kVenueIDKey];
}

- (NSString *)identifier
{
    return self.jsonDict[kVenueIdentifierKey];
}

- (NSDictionary *)metas
{
    return self.jsonDict[kVenueMetasKey];
}

- (NSString *)name
{
    return self.jsonDict[kVenueNameKey];
}

- (NSString *)state
{
    return self.jsonDict[kVenueStateKey];
}

- (NSInteger)user
{
    return [self.jsonDict[kVenueUserKey] integerValue];
}

- (NSString *)zip
{
    return self.jsonDict[kVenueZipKey];
}

@end
