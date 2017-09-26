//
//  NSMutableArray+EventEspresso.m
//  EventEspressoHD
//
//  Utilities for dealing with arrays full of EventEspresso objects.
//
//  Created by Michael A. Crawford on 2/2/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "EEAttendee.h"
#import "EERegistration.h"
#import "NSMutableArray+EventEspresso.h"

@implementation NSMutableArray (EventEspresso)

- (NSUInteger)numCheckInsRemaining
{
    NSUInteger numCheckInsRemaining = 0;
    
    for ( EERegistration* registration in self )
    {
        if ( NO == registration.isCheckedIn )
        {
            numCheckInsRemaining++;
        }
    }
    
    return numCheckInsRemaining;
}

- (NSUInteger)replaceMatchingRegistration:(EERegistration *)registration
{
    // Perform a linear search for the registration with matching ID. Once found,
    // replace object and return index. If not found, return NSNotFound.  The
    // test we use for a match is the ID. We chose this because even in a group
    // registration with one attendee, this will be unique.  If were paranoid,
    // we could also verify the code and Attendee.id but for now, we assume this
    // is overkill.
    NSUInteger index = [self indexOfObjectWithOptions:NSEnumerationConcurrent passingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        if ( [[(EERegistration *)obj ID] isEqualToNumber:registration.ID] )
        {
            *stop = YES;
        }
        
        return *stop;
    }];
    
    if ( index != NSNotFound )
    {
        [self replaceObjectAtIndex:index withObject:registration];
    }
    
    return index;
}

- (NSUInteger)removeDuplicateAttendees
{
    // We can't work on an array with less than two elements since it would be
    // impossible for there to be a duplicate.
    if ( self.count < 2 )
    {
        return 0;
    }
    
    // Iterate through the array looking for and indexing duplicates to the
    // current registration.
    //
    // This algorithm assumes that the elements are sorted and presented in
    // registration.ID order (I have observed this to be the case up til now,
    // with the results returned from a fetch).  This being the case, we don't
    // have to search the entire array looking for duplicate registrations to
    // the one current cursor.  We can assume that only remaining registrations,
    // with higher indexes, need to be searched.  Once we find a registration
    // that does not contain a duplicate, it becomes the new cursor.
    //
    // Any duplicates found are indexed and then the index is used to removed
    // them from this array as a final step.
    
    NSMutableIndexSet* indexSet = [NSMutableIndexSet new];
    NSUInteger count = self.count;
    NSUInteger cursor = 0;
    NSUInteger index = 0;
    
    while ( (cursor < count - 1) && (index != count) )
    {
        EERegistration* leftHandReg = [self objectAtIndex:cursor];
        
        for ( index = cursor + 1; index < count; ++index )
        {
            EERegistration* rightHandReg = [self objectAtIndex:index];
            
            if ( [leftHandReg.attendee.ID isEqualToNumber:rightHandReg.attendee.ID] )
            {
                [indexSet addIndex:index];
            }
            else
            {
                cursor = index;
                break;
            }
        }
    }
    
    [self removeObjectsAtIndexes:indexSet];
    return indexSet.count;
}

- (NSUInteger)assignDuplicateAttendees
{
    // This algorith behaves almost identically to removeDuplicateAttendees. (I
    // may decide to integrate them later but for now, they are experimental.)
    // The difference is that instead of deleting the duplicate attendee
    // registrations, this algorithm assigns them to the first instance of the
    // matching attendee registration.

    if ( self.count < 2 )
    {
        return 0;
    }
    
    NSMutableIndexSet* indexSet = [NSMutableIndexSet new];
    NSUInteger count = self.count;
    NSUInteger cursor = 0;
    NSUInteger index = 0;
    
    while ( (cursor < count - 1) && (index != count) )
    {
        EERegistration* leftHandReg = [self objectAtIndex:cursor];
        NSMutableArray* additionalTickets = [NSMutableArray new];
        
        for ( index = cursor + 1; index < count; ++index )
        {
            EERegistration* rightHandReg = [self objectAtIndex:index];
            
            if ( [leftHandReg.attendee.ID isEqualToNumber:rightHandReg.attendee.ID] )
            {
                // When a matching attendee registration is found, we add it to
                // the additional-tickets array so that it may later be associated
                // with the first attendee registration instance.
                [additionalTickets addObject:rightHandReg];
                [indexSet addIndex:index];
            }
            else
            {
                // Match not found in sequence, start over with the next attendee-
                // registration but first, assign any accumulated duplicate
                // attendee-registrations to the first instance. Note: This array
                // may be empty.
                cursor = index;
                break;
            }
        }
        
        leftHandReg.additionalTickets = additionalTickets;
    }
    
    [self removeObjectsAtIndexes:indexSet];
    return indexSet.count;
}

- (void)stripNullValues
{
    for ( int i = [self count] - 1; i >= 0; i-- )
    {
        id value = [self objectAtIndex:i];
        
        if ( [NSNull null] == value )
        {
            [self removeObjectAtIndex:i];
        }
        else if ( [value isKindOfClass:[NSArray class]] ||
                 [value isKindOfClass:[NSDictionary class]])
        {
            if ( NO == [value respondsToSelector:@selector(setObject:forKey:)] &&
                NO == [value respondsToSelector:@selector(addObject:)] )
            {
                value = [value mutableCopy];
                [self replaceObjectAtIndex:i withObject:value];
            }
            
            [value stripNullValues];
        }
    }
}

@end
