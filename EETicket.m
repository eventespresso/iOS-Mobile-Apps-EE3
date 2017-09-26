//
//  EETicket.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EETicket.h"


NSString* const kTicketAttendeeIDKey        = @"attendee_id";
NSString* const kTicketEventCodeKey         = @"event_code";
NSString* const kTicketRegistrationIDKey    = @"registration_id";

@implementation EETicket

#pragma mark - Initialization

+ (id)ticketWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"%@: Event Code: %@, Attendee ID: %@, Reg ID: %@",
            [super debugDescription],
            self.jsonDict[kTicketEventCodeKey],
            self.jsonDict[kTicketAttendeeIDKey],
            self.jsonDict[kTicketRegistrationIDKey]];
}

#pragma mark - Properties

- (NSString *)attendeeID
{
    return self.jsonDict[kTicketAttendeeIDKey];
}

- (NSString *)eventCode
{
    return self.jsonDict[kTicketEventCodeKey];
}

- (NSString *)registrationID
{
    return self.jsonDict[kTicketRegistrationIDKey];
}

@end
