//
//  EERegistration.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 10/27/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EEDateTime.h"
#import "EEEvent.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EETransaction.h"
#import "NSMutableArray+EventEspresso.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kRegistrationAttendeeKey    = @"Attendee";
NSString* const kRegistrationCodeKey        = @"code";
NSString* const kRegistrationDateKey        = @"date_of_registration";
NSString* const kRegistrationDatetimeKey    = @"Datetime";
NSString* const kRegistrationEventKey       = @"Event";
NSString* const kRegistrationFinalPriceKey  = @"final_price";
NSString* const kRegistrationIDKey          = @"id";
NSString* const kRegistrationIsCheckedInKey = @"is_checked_in";
NSString* const kRegistrationIsGoingKey     = @"is_going";
NSString* const kRegistrationIsGroupRegKey  = @"is_group_registration";
NSString* const kRegistrationIsPrimaryKey   = @"is_primary";
NSString* const kRegistrationPriceKey       = @"Price";
NSString* const kRegistrationStatusKey      = @"status";
NSString* const kRegistrationTransactionKey = @"Transaction";
NSString* const kRegistrationURLLinkKey     = @"url_link";

@interface EERegistration ()
{
    EEAttendee*         _attendee;
	EEDateTime*         _datetime;
	EEEvent*            _event;
    NSDecimalNumber*    _finalPrice;
	EEPrice*            _price;
	EETransaction*      _transaction;
}

@end

@implementation EERegistration

#pragma mark - Initialization

+ (id)registrationWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kRegistrationCodeKey, kRegistrationDateKey,
        kRegistrationStatusKey, kRegistrationURLLinkKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Public Methods

- (NSUInteger)replaceMatchingRegistration:(EERegistration *)registration
{
    // First test against this registration.  If the IDs match, update the contents
    // of this registration with the contents of the returned record, being sure
    // to ignore the additionAttendeeRegistration array.  Othwerise . . .
    if ( [self.attendee.ID isEqualToNumber:registration.attendee.ID] )
    {
        [self.jsonDict addEntriesFromDictionary:registration.jsonDict];
        return 0;
    }

    // Perform a linear search for the registration with matching ID. Once found,
    // replace object and return index. If not found, return NSNotFound.  The
    // test we use for a match is the ID. We chose this because even in a group
    // registration with one attendee, this will be unique.  If were paranoid,
    // we could also verify the code and Attendee.id but for now, we assume this
    // is overkill.
    return [self.additionalTickets replaceMatchingRegistration:registration];
}


#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> {ID:%@ CODE:%@ %@ %@ %@ %@; %@}",
            self.class,
            self,
            self.ID,
            self.code,
            (self.isGroupRegistration ? (self.isPrimary ? @"G-PRI" : @"G-SEC") : @"SNGL"),
            self.attendee.debugDescription,
            self.event.debugDescription,
            self.transaction.debugDescription,
            self.isCheckedIn ? @"checked-in" : @"checked-out"];
}

#pragma mark - Properties

- (EEAttendee *)attendee
{
    if ( nil == _attendee )
    {
    	_attendee = [[EEAttendee alloc] initWithJSONDictionary:self.jsonDict[kRegistrationAttendeeKey]];
    }
    return _attendee;
}

- (NSString *)attendeeLastName
{
    // This method is required in order to display an indexed table-view.
    // It is used by UILocalizedIndexedCollation.
    return self.attendee.lastname;
}

- (NSString *)code
{
    return self.jsonDict[kRegistrationCodeKey];
}

- (NSString *)date
{
    return self.jsonDict[kRegistrationDateKey];
}

- (EEDateTime *)datetime
{
    if ( nil == _datetime )
    {
    	_datetime = [[EEDateTime alloc] initWithJSONDictionary:self.jsonDict[kRegistrationDatetimeKey]];
    }
    return _datetime;
}

- (EEEvent *)event
{
    if ( nil == _event )
    {
    	_event = [[EEEvent alloc] initWithJSONDictionary:self.jsonDict[kRegistrationEventKey]];
    }
    return _event;
}

- (NSDecimalNumber *)finalPrice
{
    if ( nil == _finalPrice )
    {
        id object = self.jsonDict[kRegistrationFinalPriceKey];
        
        if ( [object class] == [NSString class] )
        {
            _finalPrice = [NSDecimalNumber decimalNumberWithString:self.jsonDict[kRegistrationFinalPriceKey]];
        }
        else // NSNumber
        {
            _finalPrice = [NSDecimalNumber decimalNumberWithDecimal:[object decimalValue]];
        }
    }
    
    return _finalPrice;
}

- (NSNumber *)ID
{
    return self.jsonDict[kRegistrationIDKey];
}

- (BOOL)isCheckedIn
{
    return [self.jsonDict[kRegistrationIsCheckedInKey] boolValue];
}

- (BOOL)isGoing
{
    return [self.jsonDict[kRegistrationIsGoingKey] boolValue];
}

- (BOOL)isGroupRegistration
{
    return [self.jsonDict[kRegistrationIsGroupRegKey] boolValue];
}

- (BOOL)isPrimary
{
    return [self.jsonDict[kRegistrationIsPrimaryKey] boolValue];
}

- (EEPrice *)price
{
    if ( nil == _price )
    {
    	_price = [[EEPrice alloc] initWithJSONDictionary:self.jsonDict[kRegistrationPriceKey]];
    }
    return _price;
}

- (NSString *)status
{
    return self.jsonDict[kRegistrationStatusKey];
}

- (NSUInteger)ticketsPurchased
{
    if ( self.additionalTickets )
    {
        return self.additionalTickets.count + 1;
    }
    
    return 1;
}

- (NSUInteger)ticketsRedeemed
{
    // Count up the additional tickets that are checked-in then add the this
    // ticket (registration) if also checked-in.
    NSUInteger count = 0;
    
    for ( EERegistration* reg in self.additionalTickets )
    {
        if ( reg.isCheckedIn )
        {
            count++;
        }
    }
    
    if ( self.isCheckedIn )
    {
        count++;
    }
    
    return count;
}

- (EETransaction *)transaction
{
    	_transaction = [[EETransaction alloc] initWithJSONDictionary:self.jsonDict[kRegistrationTransactionKey]];
    
    return _transaction;
}

- (NSString *)urlLink
{
    return self.jsonDict[kRegistrationURLLinkKey];
}

@end
