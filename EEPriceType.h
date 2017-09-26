//
//  EEPriceType.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kPriceTypeIDKey;
extern NSString* const kPriceTypeIsDiscountKey;
extern NSString* const kPriceTypeIsGlobalKey;
extern NSString* const kPriceTypeIsMemberKey;
extern NSString* const kPriceTypeIsPercentKey;
extern NSString* const kPriceTypeIsTaxKey;
extern NSString* const kPriceTypeNameKey;
extern NSString* const kPriceTypeOrderKey;

@interface EEPriceType : EEJSONObject

@property (assign, nonatomic, readonly) NSInteger ID;
@property (assign, nonatomic, readonly) BOOL      isDiscount;
@property (assign, nonatomic, readonly) BOOL      isGlobal;
@property (assign, nonatomic, readonly) BOOL      isMember;
@property (assign, nonatomic, readonly) BOOL      isPercent;
@property (assign, nonatomic, readonly) BOOL      isTax;
@property (strong, nonatomic, readonly) NSString* name;
@property (assign, nonatomic, readonly) BOOL      order;

+ (id)priceTypeWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
