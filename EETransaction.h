//
//  EETransaction.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/14/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kTransactionAmountPaidKey;
extern NSString* const kTransactionDetailsKey;
extern NSString* const kTransactionIDKey;
extern NSString* const kTransactionPaymentGatewayKey;
extern NSString* const kTransactionRegistrationsKey;
extern NSString* const kTransactionSessionDataKey;
extern NSString* const kTransactionStatusKey;
extern NSString* const kTransactionTaxDataKey;
extern NSString* const kTransactionTimestampKey;
extern NSString* const kTransactionTotalKey;

typedef NS_ENUM(NSInteger, EERegStatus) {
    EERegStatusComplete,
    EERegStatusOpen,
    EERegStatusPending,
    EERegStatusUnknown
};

@class EEDateTime;

@interface EETransaction : EEJSONObject

@property (strong, nonatomic, readonly) NSDecimalNumber*    amountPaid;
@property (strong, nonatomic, readonly) NSDictionary*       details;
@property (strong, nonatomic, readonly) NSNumber*           ID;
@property (strong, nonatomic, readonly) NSString*           paymentGateway;
@property (strong, nonatomic, readonly) NSArray*            registrations;
@property (strong, nonatomic, readonly) NSString*           sessionData;
@property (assign, nonatomic, readonly) EERegStatus         status;
@property (assign, nonatomic, readonly) NSString*           statusRaw;
@property (strong, nonatomic, readonly) NSString*           taxData;
@property (strong, nonatomic, readonly) EEDateTime*         timestamp;
@property (strong, nonatomic, readonly) NSDecimalNumber*    total;

+ (id)transactionWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
