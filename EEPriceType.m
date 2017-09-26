//
//  EEPriceType.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/13/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEPriceType.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kPriceTypeIDKey         = @"id";
NSString* const kPriceTypeIsDiscountKey = @"is_discount";
NSString* const kPriceTypeIsGlobalKey   = @"is_global";
NSString* const kPriceTypeIsMemberKey   = @"is_member";
NSString* const kPriceTypeIsPercentKey  = @"is_percent";
NSString* const kPriceTypeIsTaxKey      = @"is_tax";
NSString* const kPriceTypeNameKey       = @"name";
NSString* const kPriceTypeOrderKey      = @"order";

@implementation EEPriceType

#pragma mark - Initialization

+ (id)priceTypeWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kPriceTypeNameKey];
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

- (NSInteger)ID
{
    return [self.jsonDict[kPriceTypeIDKey] integerValue];
}

- (BOOL)isDiscount
{
    return [self.jsonDict[kPriceTypeIsDiscountKey] boolValue];
}

- (BOOL)isGlobal
{
    return [self.jsonDict[kPriceTypeIsGlobalKey] boolValue];
}

- (BOOL)isMember
{
    return [self.jsonDict[kPriceTypeIsMemberKey] boolValue];
}

- (BOOL)isPercent
{
    return [self.jsonDict[kPriceTypeIsPercentKey] boolValue];
}

- (BOOL)isTax
{
    return [self.jsonDict[kPriceTypeIsTaxKey] boolValue];
}

- (NSString *)name
{
    return self.jsonDict[kPriceTypeNameKey];
}

- (BOOL)order
{
    return [self.jsonDict[kPriceTypeOrderKey] boolValue];
}

@end
