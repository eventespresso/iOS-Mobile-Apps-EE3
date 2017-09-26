//
//  EECurrencyFormatter.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EECurrencyFormatter.h"


static EECurrencyFormatter* currencyFormatter = nil;

@interface EECurrencyFormatter ()
{
    NSNumberFormatter* numberFormatter;
}

@end

@implementation EECurrencyFormatter

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        // Initialize currency-formatter.
        numberFormatter = [NSNumberFormatter new];
        numberFormatter.numberStyle = NSNumberFormatterCurrencyStyle;
    }
    
    return self;
}

+ (EECurrencyFormatter *)sharedFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        currencyFormatter = [[self class] new];
    });
    
    return currencyFormatter;
}

- (NSString *)stringFromNumber:(NSNumber *)number
{
    return [numberFormatter stringFromNumber:number];
}

@end
