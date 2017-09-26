//
//  EEEventTicketStats.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 1/26/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EEEventTicketStats : NSObject

@property (nonatomic, assign, readonly) NSInteger numFreeAdmissionTickets;
@property (nonatomic, assign, readonly) NSInteger numTicketsPaid;
@property (nonatomic, assign, readonly) NSInteger numTicketsRedeemed;
@property (nonatomic, assign, readonly) NSInteger numTicketsSold;
@property (nonatomic, assign, readonly) NSInteger numTicketsUnpaid;
@property (nonatomic, assign, readonly) NSInteger numTicketsUnredeemed;

- (id)initWithRegistrations:(NSArray *)registrations;

@end
