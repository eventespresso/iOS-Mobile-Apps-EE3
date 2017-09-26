//
//  NSUserDefaults+EventEspresso.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 8/16/12.
//  Copyright (c) 2012 EventEspresso. All rights reserved.
//

typedef NS_ENUM(NSInteger, EventDateFilter)
{
    EventDateFilterToday = 0,
    EventDateFilterUpcoming,
    EventDateFilterPast,
    EventDataFilterCount = 3
};

@interface NSUserDefaults (EventEspresso)

@property (nonatomic, assign) NSInteger         attendeeIndexListThreshold;
@property (nonatomic, assign) NSInteger         attendeesQueryLimit;
@property (nonatomic, retain) NSString*         endpoint;
@property (nonatomic, assign) EventDateFilter   eventDateFilter;
@property (nonatomic, assign) NSInteger         eventIndexListThreshold;
@property (nonatomic, assign) NSInteger         eventsQueryLimit;
@property (nonatomic, assign) NSUInteger        fetchRequestCount;
@property (nonatomic, assign) BOOL              fetchRequestSucceeded;
@property (nonatomic, retain) NSString*         password;
@property (nonatomic, assign) NSInteger         registrationsQueryLimit;
@property (nonatomic, assign) NSTimeInterval    restAPIRequestTimeout;
@property (nonatomic, retain) NSString*         sessionKey;
@property (nonatomic, assign) BOOL              sortByDate;
@property (nonatomic, retain) NSString*         username;

- (void)clearDefaultPassword;

@end
