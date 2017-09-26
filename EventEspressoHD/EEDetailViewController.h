//
//  EEDetailViewController.h
//  EventEspressoHD
//
//  The detail view-controller for EventEspressoHD displays the attendee-
//  registration information.  It is equivalent to the EEAttendeeViewController
//  for the iPhone version of the app.
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>


#import "EEAttendeeInfoViewController.h"
#import "EEScanViewController_iPad.h"

extern NSString* const kTicketStatsUpdatedNotification;

@class EEEvent;
@class EEEventTicketStats;

@interface EEDetailViewController : UITableViewController <UISearchBarDelegate, UISplitViewControllerDelegate, EEAttendeeInfoViewControllerDelegate, EEScanViewControllerDelegate>

@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EEEvent* event;
@property (strong, nonatomic) EEEventTicketStats* ticketStats;

@property (strong, nonatomic) IBOutlet UITableView* attendeesTableView;

- (IBAction)scan:(id)sender;

@end
