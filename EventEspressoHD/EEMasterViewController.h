//
//  EEMasterViewController.h
//  EventEspressoHD
//
//  The master view-controller for EventEspressoHD displays the events table-
//  view.  It is equivalent to the EEEventsViewController for the iPhone version
//  of the app.
//
//  Created by Michael A. Crawford on 9/28/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EELoginViewController_iPad.h"


@class EEDetailViewController;

@interface EEMasterViewController : UITableViewController <UIActionSheetDelegate, EELoginViewControllerDelegate>

@property (strong, nonatomic) EEDetailViewController*   detailViewController;
@property (strong, nonatomic) NSString*                 endpoint;

@property (strong, nonatomic) IBOutlet UITableView* eventsTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem* menuButton;

- (IBAction)displayMenu:(id)sender;

@end
