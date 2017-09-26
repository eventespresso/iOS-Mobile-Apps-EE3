//
//  EEAdditionalAttendeeViewController.h
//  EventEspressoHD
//
//  Controller for displaying additional attendees associated with a group
//  registration.
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol EEAdditionalAttendeeViewControllerDelegate;

@class EERegistration;

@interface EEAdditionalAttendeeViewController : UITableViewController

@property (strong, nonatomic) EERegistration* registration;

@property (strong, nonatomic) IBOutlet UILabel* emailLabel;
@property (strong, nonatomic) IBOutlet UILabel* eventTimeLabel;
@property (strong, nonatomic) IBOutlet UILabel* nameLabel;
@property (strong, nonatomic) IBOutlet UILabel* paymentStatusLabel;
@property (strong, nonatomic) IBOutlet UILabel* paymentTypeLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceOptionLabel;
@property (strong, nonatomic) IBOutlet UILabel* priceLabel;
@property (strong, nonatomic) IBOutlet UILabel* registrationDateLabel;
@property (strong, nonatomic) IBOutlet UILabel* registrationCodeLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsPurchasedLabel;
@property (strong, nonatomic) IBOutlet UILabel* ticketsRedeemedLabel;

@property (strong, nonatomic) IBOutlet UITableView* attendeeInfoTableView;

@property (strong, nonatomic) IBOutlet UIBarButtonItem* checkInOutButton;

@property (weak, nonatomic) id<EEAdditionalAttendeeViewControllerDelegate> delegate;
@property (assign, nonatomic) BOOL disableCheckInCheckOut;
@property (assign, nonatomic) BOOL disableDoneButton;
@property (assign, nonatomic) NSUInteger ticketsPurchased;
@property (assign, nonatomic) NSUInteger ticketsRedeemed;

- (IBAction)checkIn:(id)sender;
- (IBAction)checkOut:(id)sender;
- (IBAction)done:(id)sender;

@end

@protocol EEAdditionalAttendeeViewControllerDelegate

@required

- (void)receivedUpdatedRegistration:(EERegistration *)registration;

@end