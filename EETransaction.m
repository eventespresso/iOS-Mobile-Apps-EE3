//
//  EETransaction.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEDateTime.h"
#import "EETransaction.h"
#import "NSMutableDictionary+EventEspresso.h"

NSString* const kTransactionAmountPaidKey           = @"paid";
NSString* const kTransactionDetailsKey              = @"details";
NSString* const kTransactionIDKey                   = @"id";
NSString* const kTransactionPaymentGatewayKey       = @"payment_gateway";
NSString* const kTransactionRegistrationsKey        = @"Registrations";
NSString* const kTransactionSessionDataKey          = @"session_data";
NSString* const kTransactionStatusKey               = @"status";
NSString* const kTransactionTaxDataKey              = @"tax_data";
NSString* const kTransactionTimestampKey            = @"timestamp";
NSString* const kTransactionTotalKey                = @"total";

@interface EETransaction ()
{
    NSDecimalNumber*    _amountPaid;
    EERegStatus         _status;
    dispatch_once_t     _statusOnceToken;
    EEDateTime*         _timestamp;
    NSDecimalNumber*    _total;
}

@end

@implementation EETransaction

#pragma mark - Initialization

+ (id)transactionWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    return [[[self class] alloc] initWithJSONDictionary:jsonDict];
}

- (id)initWithJSONDictionary:(NSMutableDictionary *)jsonDict
{
    self = [super initWithJSONDictionary:jsonDict];
    
    if ( self )
    {
        // Convert the NULLs that make sense . . .
        NSArray* keys = @[kTransactionDetailsKey, kTransactionPaymentGatewayKey,
        kTransactionRegistrationsKey, kTransactionStatusKey, kTransactionTaxDataKey];
        [self.jsonDict replaceNullValuesForKeys:keys withValue:@"N/A"];
        
        // . . . strip the rest.
        [self.jsonDict stripNullValues];
    }
    
    return self;
}

#pragma mark - Overrides

- (NSString *)debugDescription
{
    return [NSString stringWithFormat:@"<%@: %p> {ID:%@ STAT:%@ GW:%@ $%@}",
            self.class,
            self,
            self.ID,
            self.statusRaw,
            self.paymentGateway,
            self.amountPaid];
}

#pragma mark - Properties

- (NSDecimalNumber *)amountPaid
{
    if ( nil == _amountPaid )
    {
        id object = self.jsonDict[kTransactionAmountPaidKey];
        
        if ( [object class] == [NSString class] )
        {
            _amountPaid = [NSDecimalNumber decimalNumberWithString:object];
        }
        else // NSNumber
        {
            _amountPaid = [NSDecimalNumber decimalNumberWithDecimal:[object decimalValue]];
        }
    }
    return _amountPaid;
}

- (NSDictionary *)details
{
    return self.jsonDict[kTransactionDetailsKey];
}

- (NSNumber *)ID
{
    return self.jsonDict[kTransactionIDKey];
}

- (NSString *)paymentGateway
{
    NSString* paymentGateway = self.jsonDict[kTransactionPaymentGatewayKey];
    
    if ( nil == paymentGateway || 0 == paymentGateway.length )
    {
        return @"N/A";
    }
    
    return paymentGateway;
}

- (NSArray *)registrations
{
    return self.jsonDict[kTransactionRegistrationsKey];
}

- (NSString *)sessionData
{
    return self.jsonDict[kTransactionSessionDataKey];
}

- (EERegStatus)status
{
    dispatch_once(&_statusOnceToken, ^{
        NSString* value = self.jsonDict[kTransactionStatusKey];
        
        if ( [value isEqualToString:@"complete"] )
        {
            _status = EERegStatusComplete;
        }
        else if ( [value isEqualToString:@"open"] )
        {
            _status = EERegStatusOpen;
        }
        else if ( [value isEqualToString:@"pending"] )
        {
            _status = EERegStatusPending;
        }
        else
        {
            _status = EERegStatusUnknown;
        }
    });
    
    return _status;
}

- (NSString *)statusRaw
{
#if 0
    return self.jsonDict[kTransactionStatusKey];
#else
    NSString* status = self.jsonDict[kTransactionStatusKey];
    
    if ( [status isKindOfClass:[NSNull class]] )
    {
        return @"";
    }
    
    return status;
#endif
}

- (NSString *)taxData
{
    return self.jsonDict[kTransactionTaxDataKey];
}

- (EEDateTime *)timestamp
{
    if ( nil == _timestamp )
    {
        _timestamp = [[EEDateTime alloc] initWithJSONDictionary:self.jsonDict[kTransactionTimestampKey]];
    }
    return _timestamp;
}

- (NSDecimalNumber *)total
{
    if ( nil == _total )
    {
        id object = self.jsonDict[kTransactionTotalKey];
        
        if ( [object class] == [NSString class] )
        {
            _total = [NSDecimalNumber decimalNumberWithString:object];
        }
        else // NSNumber
        {
            _total = [NSDecimalNumber decimalNumberWithDecimal:[object decimalValue]];
        }
    }
    return _total;
}

@end
