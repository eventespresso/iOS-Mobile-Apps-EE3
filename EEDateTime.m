//
//  EEDateTime.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEDateTime.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kDatetimeEventEndKey    = @"event_end";
NSString* const kDatetimeEventStartKey  = @"event_start";
NSString* const kDatetimeIDKey          = @"id";
NSString* const kDatetimeIsPrimaryKey   = @"is_primary";
NSString* const kDatetimeLimitKey       = @"limit";
NSString* const kDatetimeRegEndKey      = @"registration_end";
NSString* const kDatetimeRegStartKey    = @"registration_start";
NSString* const kDatetimeTicketsLeftKey = @"tickets_left";

@implementation EEDateTime

#pragma mark - Initialization

+ (id)datetimeWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kDatetimeEventEndKey, kDatetimeEventStartKey,
        kDatetimeRegEndKey, kDatetimeRegStartKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@ %@", self.eventStart, self.eventEnd];
}

#pragma mark - Properties

- (NSString *)eventEnd
{
    return self.jsonDict[kDatetimeEventEndKey];
}

- (NSString *)eventEndDate
{
    return [self.eventEnd componentsSeparatedByString:@" "][0];
}

- (NSString *)eventEndTime
{
    return [self.eventEnd componentsSeparatedByString:@" "][1];
}

- (NSString *)eventStart
{
    return self.jsonDict[kDatetimeEventStartKey];
}

- (NSString *)eventStartDate
{
    return [self.eventStart componentsSeparatedByString:@" "][0];
}

- (NSString *)eventStartTime
{
    return [self.eventStart componentsSeparatedByString:@" "][1];
}

- (NSNumber *)ID
{
    return self.jsonDict[kDatetimeIDKey];
}

- (BOOL)isPrimary
{
    return [self.jsonDict[kDatetimeIsPrimaryKey] boolValue];
}

- (NSInteger)limit
{
    return [self.jsonDict[kDatetimeLimitKey] integerValue];
}

- (NSString *)registrationEnd
{
    return self.jsonDict[kDatetimeRegEndKey];
}

- (NSString *)registrationStart
{
    return self.jsonDict[kDatetimeRegStartKey];
}

- (NSInteger)ticketsLeft
{
    return [self.jsonDict[kDatetimeTicketsLeftKey] integerValue];
}

- (NSInteger)ticketsRedeemed
{
    return self.limit - self.ticketsLeft;
}

@end
