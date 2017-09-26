//
//  EETicket.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "EEJSONObject.h"


extern NSString* const kTicketAttendeeIDKey;
extern NSString* const kTicketEventCodeKey;
extern NSString* const kTicketRegistrationIDKey;

@interface EETicket : EEJSONObject

@property(nonatomic, strong) NSString* attendeeID;
@property(nonatomic, strong) NSString* eventCode;
@property(nonatomic, strong) NSString* registrationID;

+ (id)ticketWithJSONDictionary:(NSMutableDictionary *)jsonDict;

@end
