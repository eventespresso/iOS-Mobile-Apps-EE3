//
//  NSMutableArray+EventEspresso.h
//  EventEspressoHD
//
//  Utilities for dealing with arrays full of EventEspresso objects.
//
//  Created by Michael A. Crawford on 2/2/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EERegistration;

@interface NSMutableArray (EventEspresso)

// Removes duplicate registrations for each found attendee and assigns them as
// extra tickets to the first instance.  This method is intended to provide
// output suitable for the attendee-info view.
- (NSUInteger)assignDuplicateAttendees;

- (NSUInteger)numCheckInsRemaining;

// Returns NSNotFound if there is no match.  Otherwise the index for the matching
// item is returned.
- (NSUInteger)replaceMatchingRegistration:(EERegistration *)registration;

// Removes duplicate registrations for each found attendee.  This method is
// intended to provide output suitable for the main attendee table-view.
- (NSUInteger)removeDuplicateAttendees;

- (void)stripNullValues;
@end
