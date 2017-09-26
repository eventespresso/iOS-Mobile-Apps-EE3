//
//  EEAttendeeInfoViewController.h
//  EventEspressoHD
//
//  Created by Michael A. Crawford on 11/12/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "EEAdditionalAttendeeViewController.h"
#import "EEInOutQuantityViewController.h"

@class EERegistration;

@protocol EEAttendeeInfoViewControllerDelegate;

@interface EEAttendeeInfoViewController : UITableViewController  <UIPopoverControllerDelegate,EEAdditionalAttendeeViewControllerDelegate, EEInOutQuantityViewControllerDelegate>

@property (weak, nonatomic) id<EEAttendeeInfoViewControllerDelegate> delegate;
@property (strong, nonatomic) NSString* endpoint;
@property (strong, nonatomic) EERegistration* registration;


@property (strong, nonatomic) IBOutlet UITableView* attendeeInfoTableView;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *checkInOutButton;

- (IBAction)checkIn:(id)sender;
- (IBAction)checkOut:(id)sender;

@end

@protocol EEAttendeeInfoViewControllerDelegate <NSObject>

@required

- (void)receivedUpdatedRegistration:(EERegistration *)registration;

@end
