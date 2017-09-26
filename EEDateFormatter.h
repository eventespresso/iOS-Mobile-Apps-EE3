//
//  EEDateFormatter.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface EEDateFormatter : NSObject

+ (EEDateFormatter *)sharedFormatter;

- (NSDate *)dateFromString:(NSString *)string;
- (NSString *)dateStringFromBackEndDateString:(NSString *)string;
- (NSString *)dateTimeStringFromBackEndDateString:(NSString *)string;
- (NSString *)timeStringFromBackEndDateString:(NSString *)string;

@end
