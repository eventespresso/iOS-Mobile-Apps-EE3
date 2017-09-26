//
//  EEAttendeeCell.h
//  EventEspresso
//
//  Created by Michael A. Crawford on 10/19/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EEAttendeeCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* amountPaidLabel;
@property (strong, nonatomic) IBOutlet UILabel* attendeeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* eventTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* groupRegistrationLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* registrationCodeLabel;

@end
