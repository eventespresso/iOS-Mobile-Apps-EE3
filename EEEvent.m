//
//  EEEvent.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEDateFormatter.h"
#import "EEDateTime.h"
#import "EEEvent.h"
#import "NSMutableDictionary+EventEspresso.h"

// Event Keys
NSString* const kEventActiveKey             = @"active";
NSString* const kEventCategoriesKey         = @"Categories";
NSString* const kEventCodeKey               = @"code";
NSString* const kEventDatetimesKey          = @"Datetimes";
NSString* const kEventDescriptionKey        = @"description";
NSString* const kEventGroupRegAllowedKey    = @"group_registrations_allowed";
NSString* const kEventGroupRegMaxKey        = @"group_registrations_max";
NSString* const kEventIDKey                 = @"id";
NSString* const kEventLimitKey              = @"limit";
NSString* const kEventMemberOnlyKey         = @"member_only";
NSString* const kEventMetadataKey           = @"metadata";
NSString* const kEventNameKey               = @"name";
NSString* const kEventPromoCodesKey         = @"Promocodes";
NSString* const kEventVenuesKey             = @"Venues";
NSString* const kEventStatusKey             = @"status";

// Event Metadata Keys
NSString* const kEventAdditionalAttendeeRegInfoKey  = @"additional_attendee_reg_info";
NSString* const kEventAddAttendeeQuestionGroupsKey  = @"add_attende_question_groups";
NSString* const kEventDateSubmittedKey              = @"date_submitted";
NSString* const kEventDefaultPaymentStatusKey       = @"default_payment_status";
NSString* const kEventThumbnailURLKey               = @"event_thumbnail_url";
NSString* const kEventHashTagKey                    = @"event_hashtag";
NSString* const kEventVenueIDKey                    = @"venue_id";

@implementation EEEvent

#pragma mark - Initialization

+ (id)eventWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kEventCodeKey, kEventDescriptionKey, kEventNameKey,
        kEventStatusKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
        
        // get start date/time and make it an object
        _startDate = [[EEDateFormatter sharedFormatter] dateFromString:self.jsonDict[kEventDatetimesKey][0][kDatetimeEventStartKey]];
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
            self.name];
}

#pragma mark - Properties

- (BOOL)active
{
    return [self.jsonDict[kEventActiveKey] boolValue];
}

- (NSArray *)categories
{
    return self.jsonDict[kEventCategoriesKey];
}

- (NSString *)code
{
    return self.jsonDict[kEventCodeKey];
}

- (NSArray *)datetimes
{
    return self.jsonDict[kEventDatetimesKey];
}

- (NSString *)description
{
    return self.jsonDict[kEventDescriptionKey];
}

- (BOOL)groupRegAllowed
{
    return [self.jsonDict[kEventGroupRegAllowedKey] boolValue];
}

- (NSInteger)groupRegMax
{
    return [self.jsonDict[kEventGroupRegMaxKey] integerValue];
}

- (NSNumber *)ID
{
    return self.jsonDict[kEventIDKey];
}

- (NSInteger)limit
{
    return [self.jsonDict[kEventLimitKey] integerValue];
}

- (BOOL)memberOnly
{
    return [self.jsonDict[kEventMemberOnlyKey] boolValue];
}

- (NSDictionary *)metadata
{
    return self.jsonDict[kEventMetadataKey];
}

- (NSString *)name
{
    return self.jsonDict[kEventNameKey];
}

- (NSArray *)promoCodes
{
    return self.jsonDict[kEventPromoCodesKey];
}

- (NSArray *)venues
{
    return self.jsonDict[kEventVenuesKey];
}

- (NSString *)status
{
    return self.jsonDict[kEventStatusKey];
}

@end
