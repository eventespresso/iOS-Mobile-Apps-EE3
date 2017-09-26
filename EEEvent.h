//
//  EEEvent.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


// Event Keys
extern NSString* const kEventActiveKey;
extern NSString* const kEventCategoriesKey;
extern NSString* const kEventCodeKey;
extern NSString* const kEventDatetimesKey;
extern NSString* const kEventDescriptionKey;
extern NSString* const kEventGroupRegAllowedKey;
extern NSString* const kEventGroupRegMaxKey;
extern NSString* const kEventIDKey;
extern NSString* const kEventLimitKey;
extern NSString* const kEventMemberOnlyKey;
extern NSString* const kEventMetadataKey;
extern NSString* const kEventNameKey;
extern NSString* const kEventPromoCodesKey;
extern NSString* const kEventVenuesKey;
extern NSString* const kEventStatusKey;

// Event Metadata Keys

@interface EEEvent : EEJSONObject

@property (assign, nonatomic, readonly) BOOL          active;
@property (strong, nonatomic, readonly) NSArray*      categories;
@property (strong, nonatomic, readonly) NSString*     code;
@property (strong, nonatomic, readonly) NSArray*      datetimes;
@property (strong, nonatomic, readonly) NSString*     description;
@property (assign, nonatomic, readonly) BOOL          groupRegAllowed;
@property (assign, nonatomic, readonly) NSInteger     groupRegMax;
@property (strong, nonatomic, readonly) NSNumber*     ID;
@property (assign, nonatomic, readonly) NSInteger     limit;
@property (assign, nonatomic, readonly) BOOL          memberOnly;
@property (strong, nonatomic, readonly) NSDictionary* metadata;
@property (strong, nonatomic, readonly) NSString*     name;
@property (strong, nonatomic, readonly) NSArray*      promoCodes;
@property (strong, nonatomic, readonly) NSArray*      venues;
@property (strong, nonatomic, readonly) NSDate*       startDate;
@property (strong, nonatomic, readonly) NSString*     status;

+ (id)eventWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
