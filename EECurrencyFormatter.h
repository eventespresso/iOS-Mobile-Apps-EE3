//
//  EECurrencyFormatter.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EECurrencyFormatter : NSObject

+ (EECurrencyFormatter *)sharedFormatter;

- (NSString *)stringFromNumber:(NSNumber *)number;

@end
