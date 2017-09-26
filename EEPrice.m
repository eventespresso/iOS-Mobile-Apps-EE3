//
//  EEPrice.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEPrice.h"
#import "EEPriceType.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kPriceAmountKey         = @"amount";
NSString* const kPriceDescriptionKey    = @"description";
NSString* const kPriceEndDateKey        = @"end_date";
NSString* const kPriceIDKey             = @"id";
NSString* const kPriceLimitKey          = @"limit";
NSString* const kPriceNameKey           = @"name";
NSString* const kPriceRemainingKey      = @"remaining";
NSString* const kPriceStartDateKey      = @"start_date";
NSString* const kPriceTypeKey           = @"Pricetype";

@interface EEPrice ()
{
    NSDecimalNumber*    _amount;
    EEPriceType*        _type;
}

@end

@implementation EEPrice

#pragma mark - Initialization

+ (id)priceWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kPriceDescriptionKey, kPriceEndDateKey, kPriceNameKey,
        kPriceStartDateKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return self.name;
}

#pragma mark - Properties

- (NSDecimalNumber *)amount
{
    if ( nil == _amount )
    {
        id object = self.jsonDict[kPriceAmountKey];
        
        if ( [object class] == [NSString class] )
        {
            _amount = [NSDecimalNumber decimalNumberWithString:object];
        }
        else // NSNumber
        {
            _amount = [NSDecimalNumber decimalNumberWithDecimal:[object decimalValue]];
        }
    }
    
    return _amount;
}

- (NSString *)description
{
    return self.jsonDict[kPriceDescriptionKey];
}

- (NSString *)endDate
{
    return self.jsonDict[kPriceEndDateKey];
}

- (NSString *)ID
{
    return self.jsonDict[kPriceIDKey];
}

- (NSInteger)limit
{
    return [self.jsonDict[kPriceLimitKey] integerValue];
}

- (NSString *)name
{
    return self.jsonDict[kPriceNameKey];
}

- (NSInteger)remaining
{
    return [self.jsonDict[kPriceRemainingKey] integerValue];
}

- (NSString *)startDate
{
    return self.jsonDict[kPriceStartDateKey];
}

- (EEPriceType *)type
{
    if ( nil == _type )
    {
        _type = [[EEPriceType alloc] initWithJSONDictionary:self.jsonDict[kPriceTypeKey]];
    }
    return _type;
}

@end
