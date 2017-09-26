//
//  EEPrice.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"

extern NSString* const kPriceAmountKey;
extern NSString* const kPriceDescriptionKey;
extern NSString* const kPriceEndDateKey;
extern NSString* const kPriceIDKey;
extern NSString* const kPriceLimitKey;
extern NSString* const kPriceNameKey;
extern NSString* const kPriceRemainingKey;
extern NSString* const kPriceStartDateKey;
extern NSString* const kPriceTypeKey;

@class EEPriceType;

@interface EEPrice : EEJSONObject

@property (strong, nonatomic, readonly) NSDecimalNumber*    amount;
@property (strong, nonatomic, readonly) NSString*           description;
@property (strong, nonatomic, readonly) NSString*           endDate;
@property (strong, nonatomic, readonly) NSString*           ID;
@property (assign, nonatomic, readonly) NSInteger           limit;
@property (strong, nonatomic, readonly) NSString*           name;
@property (assign, nonatomic, readonly) NSInteger           remaining;
@property (strong, nonatomic, readonly) NSString*           startDate;
@property (strong, readonly) EEPriceType*                   type;

+ (id)priceWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
