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

#import <Foundation/Foundation.h>

#import "EERegistration.h"

@class EEAttendee, EEDateTime, EEEvent, EEPrice, EETransaction;

@interface EEGroupRegistration : EERegistration

@property (nonatomic, strong, readonly) NSArray* additionalAttendeeRegistrations;

+ (id)registrationWithRegistration:(EERegistration *)registration group:(NSArray *)group;

- (BOOL)updateAdditionalAttendeeRegistration:(EERegistration *)registration;

@end
