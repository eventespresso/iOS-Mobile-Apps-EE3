//
//  EEEventInfoViewController.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>


@class EEDetailViewController;
@class EEEvent;
@class EEEventTicketStats;

@interface EEEventInfoViewController : UITableViewController

@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent*  event;
@property (strong, nonatomic) EEDetailViewController* detailViewController;

@property (strong, nonatomic) IBOutlet UILabel* capacityLabel;
@property (strong, nonatomic) IBOutlet UILabel* endDateLabel;
@property (strong, nonatomic) IBOutlet UILabel* endTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* freeAdmissionLabel;
@property (strong, nonatomic) IBOutlet UILabel* nameLabel;
@property (strong, nonatomic) IBOutlet UILabel* startDateLabel;
@property (strong, nonatomic) IBOutlet UILabel* startTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsAvailableLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsPaidLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsRedeemedLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsSoldLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsUnpaidLabel;
@property (strong, nonatomic) IBOutlet UILabel* venueLabel;

@property (strong, nonatomic) IBOutlet UITableViewCell* venueCell;

@end
