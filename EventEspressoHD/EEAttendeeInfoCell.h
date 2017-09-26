//
//  EEAttendeeInfoCell.h
//  EventEspressoHD
//
//  This cell type is used in the AttendeeInfo view to display the different
//  attendee and registration information.
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface EEAttendeeInfoCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UILabel* contentLabel;
@property (strong, nonatomic) IBOutlet UILabel* labelLabel;

@end
