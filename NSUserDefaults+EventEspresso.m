//
//  NSUserDefaults+EventEspresso.m
//  EventEspresso
//
//  Created by Michael A. Crawford on 8/16/12.
//  Copyright (c) 2012 EventEspresso. All rights reserved.
//

#import "NSUserDefaults+EventEspresso.h"

static NSString* const EEAttendeeIndexListThresholdKey  = @"attendeeIndexListThreshold";
static NSString* const EEAttendeesQueryLimitKey         = @"attendeesQueryLimit";
static NSString* const EEEndpointKey                    = @"endpoint";
static NSString* const EEEventDateFilterKey             = @"eventDateFilter";
static NSString* const EEEventIndexListThresholdKey     = @"eventIndexListThreshold";
static NSString* const EEEventsQueryLimitKey            = @"eventsQueryLimit";
static NSString* const EEFetchRequestCountKey           = @"fetchRequestCount";
static NSString* const EEFetchRequestSucceededKey       = @"fetchRequestSucceeded";
static NSString* const EEPasswordKey                    = @"password";
static NSString* const EERegistrationsQueryLimitKey     = @"registrationsQueryLimit";
static NSString* const EERestAPIRequestTimeoutKey       = @"restAPIRequestTimeout";
static NSString* const EESessionKeyKey                  = @"sessionKey";
static NSString* const EESortByDateKey                  = @"sortByDate";
static NSString* const EEUsernameKey                    = @"username";

@implementation NSUserDefaults (EventEspresso)

#pragma mark - Initialization

+ (void)initialize
{
    if ( self == [NSUserDefaults class] )
    {
        NSMutableDictionary* defaultValues = [NSMutableDictionary dictionary];
        defaultValues[EEAttendeeIndexListThresholdKey]  = @25;
        defaultValues[EEAttendeesQueryLimitKey]         = @0;
        defaultValues[EEEventIndexListThresholdKey]     = @25;
        defaultValues[EEEventsQueryLimitKey]            = @0;
        defaultValues[EERegistrationsQueryLimitKey]     = @0;
        defaultValues[EERestAPIRequestTimeoutKey]       = @30.0;
        defaultValues[EESortByDateKey]                  = @NO;
        [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
    }
}

#pragma mark - Public Methods

- (NSInteger)attendeeIndexListThreshold
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EEAttendeeIndexListThresholdKey];
}

- (NSInteger)attendeesQueryLimit
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EEAttendeesQueryLimitKey];
}

- (void)clearDefaultPassword
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:EEPasswordKey];
}

- (NSString *)endpoint
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EEEndpointKey];
}

- (EventDateFilter)eventDateFilter
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EEEventDateFilterKey];
}

- (NSInteger)eventIndexListThreshold
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EEEventIndexListThresholdKey];
}

- (NSInteger)eventsQueryLimit
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EEEventsQueryLimitKey];
}

- (NSUInteger)fetchRequestCount
{
    return [[[NSUserDefaults standardUserDefaults] objectForKey:EEFetchRequestCountKey] unsignedIntegerValue];
}

- (BOOL)fetchRequestSucceeded
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:EEFetchRequestSucceededKey];
}

- (NSString *)password
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EEPasswordKey];
}

- (NSInteger)registrationsQueryLimit
{
    return [[NSUserDefaults standardUserDefaults] integerForKey:EERegistrationsQueryLimitKey];
}

- (NSTimeInterval)restAPIRequestTimeout
{
    return [[NSUserDefaults standardUserDefaults] doubleForKey:EERestAPIRequestTimeoutKey];
}

- (NSString *)sessionKey
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EESessionKeyKey];
}

- (BOOL)sortByDate
{
    return [[NSUserDefaults standardUserDefaults] boolForKey:EESortByDateKey];
}

- (void)setAttendeeIndexListThreshold:(NSInteger)indexListThreshold
{
    [[NSUserDefaults standardUserDefaults] setInteger:indexListThreshold forKey:EEAttendeeIndexListThresholdKey];
}

- (void)setAttendeesQueryLimit:(NSInteger)attendeesQueryLimit
{
    [[NSUserDefaults standardUserDefaults] setInteger:attendeesQueryLimit forKey:EEAttendeesQueryLimitKey];
}

- (void)setEndpoint:(NSString *)endpoint
{
    [[NSUserDefaults standardUserDefaults] setObject:endpoint forKey:EEEndpointKey];
}

- (void)setEventDateFilter:(EventDateFilter)eventDateFilter
{
    [[NSUserDefaults standardUserDefaults] setInteger:eventDateFilter forKey:EEEventDateFilterKey];
}

- (void)setEventIndexListThreshold:(NSInteger)indexListThreshold
{
    [[NSUserDefaults standardUserDefaults] setInteger:indexListThreshold forKey:EEEventIndexListThresholdKey];
}

- (void)setEventsQueryLimit:(NSInteger)eventsQueryLimit
{
    [[NSUserDefaults standardUserDefaults] setInteger:eventsQueryLimit forKey:EEEventsQueryLimitKey];
}

- (void)setFetchRequestCount:(NSUInteger)fetchRequestCount
{
    [[NSUserDefaults standardUserDefaults] setObject:@(fetchRequestCount) forKey:EEFetchRequestCountKey];
}

- (void)setFetchRequestSucceeded:(BOOL)fetchRequestSucceeded
{
    [[NSUserDefaults standardUserDefaults] setBool:fetchRequestSucceeded forKey:EEFetchRequestSucceededKey];
}

- (void)setPassword:(NSString *)password
{
    [[NSUserDefaults standardUserDefaults] setObject:password forKey:EEPasswordKey];
}

- (void)setRegistrationsQueryLimit:(NSInteger)registrationsQueryLimit
{
    [[NSUserDefaults standardUserDefaults] setInteger:registrationsQueryLimit
                                               forKey:EERegistrationsQueryLimitKey];
}

- (void)setRestAPIRequestTimeout:(NSTimeInterval)restAPIRequestTimeout
{
    [[NSUserDefaults standardUserDefaults] setDouble:restAPIRequestTimeout forKey:EERestAPIRequestTimeoutKey];
}

- (void)setSessionKey:(NSString *)sessionKey
{
    [[NSUserDefaults standardUserDefaults] setObject:sessionKey forKey:EESessionKeyKey];
}

- (void)setSortByDate:(BOOL)sortByDate
{
    [[NSUserDefaults standardUserDefaults] setBool:sortByDate forKey:EESortByDateKey];
}

- (void)setUsername:(NSString *)username
{
    [[NSUserDefaults standardUserDefaults] setObject:username forKey:EEUsernameKey];
}

- (NSString *)username
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:EEUsernameKey];
}

@end
