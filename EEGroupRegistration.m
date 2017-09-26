//
//  EEGroupRegistration.h
//  EventEspressoHD
//
//  This utility class helps us to manage a group registration which consists of
//  multiple registration entities with different attendee.IDs.
//
//  This class inherits from EERegistration so that interface is used to get data
//  for the selected registration.  Additional attendee registrations are stored
//  in separate properties; arrays containing these respective registration
//  entities.
//
//  The complexity embodied here should go a long way to simplifying the UI
//  and business logic for group registrations.
//
//  Created by Michael A. Crawford on 1/29/13.
//  Copyright (c) 2012-2013 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EEGroupRegistration.h"

@interface EEGroupRegistration ()
{
    NSMutableArray* _additionalAttendeeRegistrations;
}
@end

@implementation EEGroupRegistration

#pragma mark - Initialization

+ (id)registrationWithRegistration:(EERegistration *)registration group:(NSArray *)group
{
    return [[[self class] alloc] initWithRegistration:registration group:group];
}

- (id)initWithRegistration:(EERegistration *)registration group:(NSArray *)group
{
    self = [super initWithJSONDictionary:registration.jsonDict];
    
    if ( self )
    {
        _additionalAttendeeRegistrations = [NSMutableArray arrayWithArray:group];
        
        // Remove selected registration.
        __block EERegistration* selection = nil;
        __block NSUInteger objIndex = NSNotFound;
        [group enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            if ( [[obj ID] isEqualToNumber:registration.ID] )
            {
                selection = obj;
                objIndex = idx;
                *stop = YES;
            }
        }];

        if ( objIndex != NSNotFound )
        {
            [_additionalAttendeeRegistrations removeObjectAtIndex:objIndex];
        }
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> {%@%@}",
            [self class],
            self,
            [self dumpThisRegistration],
            [self dumpAdditionalRegistrations]];
}

- (NSString *)dumpAdditionalRegistrations
{
    NSMutableString* s = [NSMutableString new];
    
    for ( EERegistration* reg in self.additionalAttendeeRegistrations )
    {
        [s appendString:@"\n    "];
        [s appendString:[reg debugDescription]];
    }
    
    return s;
}

- (NSString *)dumpThisRegistration
{
    NSMutableString* s = [NSMutableString new];
    [s appendString:@"\n    "];
    [s appendString:[super debugDescription]];
    return s;
}

#pragma mark - Public Methods

- (BOOL)updateAdditionalAttendeeRegistration:(EERegistration *)registration
{
    // Search secondaries for a matching registration. If found, replace match
    // with this registration.
    NSUInteger index = [_additionalAttendeeRegistrations indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj ID] isEqualToNumber:registration.ID];
    }];
    
    if ( NSNotFound == index )
    {
        return NO;
    }
    
    // The additional ticket information is not part of the back-end attendee-
    // registration record, therefore we must manually move it over from the
    // original registration to the newly updated registration.
    EERegistration* originalRegistration = [_additionalAttendeeRegistrations objectAtIndex:index];
    registration.additionalTickets = originalRegistration.additionalTickets;
    [_additionalAttendeeRegistrations replaceObjectAtIndex:index withObject:registration];
    return YES;
}


@end
