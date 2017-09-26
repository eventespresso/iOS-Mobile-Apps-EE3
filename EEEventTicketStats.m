//
//  EEEventTicketStats.m
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 1/26/13.
//  Copyright (c) 2013 Event Espresso. All rights reserved.
//

#import "EEEventTicketStats.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EETransaction.h"

@implementation EEEventTicketStats

- (id)initWithRegistrations:(NSArray *)registrations
{
    self = [super init];
    
    if ( self )
    {
        for ( EERegistration* registration in registrations )
        {
            _numTicketsSold++;
            
            if ( registration.isCheckedIn )
            {
                _numTicketsRedeemed++;
            }
            else
            {
                _numTicketsUnredeemed++;
            }
            
            if ( registration.transaction.status == EERegStatusComplete )
            {
                _numTicketsPaid++;
            }
            else
            {
                _numTicketsUnpaid++;
            }
            
            if ( registration.price.amount == 0 )
            {
                _numFreeAdmissionTickets++;   
            }
        }
    }
    
    return self;
}

@end
