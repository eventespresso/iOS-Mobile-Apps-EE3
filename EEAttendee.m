//
//  EEAttendee.m
//  EventEspressoHD
//
//  Created by Define-Jenaveve on 08/03/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EEAttendee.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kAttendeeAddress2Key    = @"address2";
NSString* const kAttendeeAddressKey     = @"address";
NSString* const kAttendeeCommentsKey    = @"comments";
NSString* const kAttendeeCountryKey     = @"country";
NSString* const kAttendeeEmailKey       = @"email";
NSString* const kAttendeeFirstNameKey   = @"firstname";
NSString* const kAttendeeIDKey          = @"id";
NSString* const kAttendeeLastNameKey    = @"lastname";
NSString* const kAttendeeNotesKey       = @"notes";
NSString* const kAttendeeRegKey         = @"Registrations";
NSString* const kAttendeePhoneKey       = @"phone";
NSString* const kAttendeeStateKey       = @"state";
NSString* const kAttendeeZipKey         = @"zip";

@implementation EEAttendee

#pragma mark - Initialization

+ (id)attendeeWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kAttendeeAddress2Key, kAttendeeAddressKey,
        kAttendeeCommentsKey, kAttendeeCountryKey, kAttendeeEmailKey,
        kAttendeeFirstNameKey, kAttendeeLastNameKey, kAttendeeNotesKey,
        kAttendeePhoneKey, kAttendeeStateKey, kAttendeeZipKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> {ID:%@ - %@}",
            [self class],
            self,
            self.ID,
            self.fullname];
}

#pragma mark - Properties

- (NSString *)address
{
    return self.jsonDict[kAttendeeAddressKey];
}

- (NSString *)address2
{
    return self.jsonDict[kAttendeeAddress2Key];
}

- (NSString *)comments
{
    return self.jsonDict[kAttendeeCommentsKey];
}

- (NSString *)country
{
    return self.jsonDict[kAttendeeCountryKey];
}

- (NSString *)email
{
    return self.jsonDict[kAttendeeEmailKey];
}

- (NSArray *)events
{
    return self.jsonDict[kAttendeeRegKey];
}

- (NSString *)firstname
{
    return self.jsonDict[kAttendeeFirstNameKey];
}

- (NSString *)fullname
{
    return [NSString stringWithFormat:@"%@ %@", self.firstname, self.lastname];
}

- (NSNumber *)ID
{
    return self.jsonDict[kAttendeeIDKey];
}

- (NSString *)lastname
{
    return self.jsonDict[kAttendeeLastNameKey];
}

- (NSString *)notes
{
    return self.jsonDict[kAttendeeNotesKey];
}

- (NSArray *)registrations
{
    return self.jsonDict[kAttendeeRegKey];
}

- (NSString *)phone
{
    return self.jsonDict[kAttendeePhoneKey];
}

- (NSString *)state
{
    return self.jsonDict[kAttendeeStateKey];
}

- (NSString *)zip
{
    return self.jsonDict[kAttendeeZipKey];
}

@end
