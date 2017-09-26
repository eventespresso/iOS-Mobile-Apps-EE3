//
//  EEDateTime.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kDatetimeEventEndKey;
extern NSString* const kDatetimeEventStartKey;
extern NSString* const kDatetimeIDKey;
extern NSString* const kDatetimeIsPrimaryKey;
extern NSString* const kDatetimeLimitKey;
extern NSString* const kDatetimeRegEndKey;
extern NSString* const kDatetimeRegStartKey;
extern NSString* const kDatetimeTicketsLeftKey;

@interface EEDateTime : EEJSONObject

@property (strong, nonatomic, readonly) NSString* eventEnd;
@property (strong, nonatomic, readonly) NSString* eventEndDate;
@property (strong, nonatomic, readonly) NSString* eventEndTime;
@property (strong, nonatomic, readonly) NSString* eventStart;
@property (strong, nonatomic, readonly) NSString* eventStartDate;
@property (strong, nonatomic, readonly) NSString* eventStartTime;
@property (assign, nonatomic, readonly) NSNumber* ID;
@property (assign, nonatomic, readonly) BOOL      isPrimary;
@property (assign, nonatomic, readonly) NSInteger limit;
@property (strong, nonatomic, readonly) NSString* registrationEnd;
@property (strong, nonatomic, readonly) NSString* registrationStart;
@property (assign, nonatomic, readonly) NSInteger ticketsLeft;
@property (assign, nonatomic, readonly) NSInteger ticketsRedeemed;

+ (id)datetimeWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
