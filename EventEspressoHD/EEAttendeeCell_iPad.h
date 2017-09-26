//
//  EEAttendeeCell_iPad.h
//  EventEspressoHD
//
//  This cell type is used when displaying both the Detail (Attendee) view and
//  the AttendeeInfo view.  In the AttendeeInfo view.
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EEAttendeeCell_iPad : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* attendeeNameLabel;
@property (strong, nonatomic) IBOutlet UILabel* groupRegistrationLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;

@end
