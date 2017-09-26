//
//  EEDateFormatter.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEDateFormatter.h"


static EEDateFormatter* dateFormatter = nil;

@interface EEDateFormatter ()
{
    NSDateFormatter* backEndDateFormatter;
    NSDateFormatter* frontEndDateFormatter;
    NSDateFormatter* frontEndDateTimeFormatter;
    NSDateFormatter* frontEndTimeFormatter;
}

@end

@implementation EEDateFormatter

- (id)init
{
    self = [super init];
    
    if ( self )
    {
        backEndDateFormatter = [NSDateFormatter new];
        [backEndDateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        
        frontEndDateFormatter = [NSDateFormatter new];
        [frontEndDateFormatter setDateFormat:@"E, MMM dd, yyyy"];
        
        frontEndDateTimeFormatter = [NSDateFormatter new];
        [frontEndDateTimeFormatter setDateFormat:@"E, MMM dd, yyyy - h:mm a"];
        
        frontEndTimeFormatter = [NSDateFormatter new];
        [frontEndTimeFormatter setDateFormat:@"h:mm a"];
    }
    
    return self;
}

+ (EEDateFormatter *)sharedFormatter
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        dateFormatter = [[self class] new];
    });
    
    return dateFormatter;
}

- (NSDate *)dateFromString:(NSString *)string
{
    return [backEndDateFormatter dateFromString:string];
}

- (NSString *)dateStringFromBackEndDateString:(NSString *)string
{
    return [frontEndDateFormatter stringFromDate:[backEndDateFormatter dateFromString:string]];
}

- (NSString *)dateTimeStringFromBackEndDateString:(NSString *)string
{
    return [frontEndDateTimeFormatter stringFromDate:[backEndDateFormatter dateFromString:string]];
}

- (NSString *)timeStringFromBackEndDateString:(NSString *)string
{
    return [frontEndTimeFormatter stringFromDate:[backEndDateFormatter dateFromString:string]];
}

@end
