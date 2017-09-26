//
//  EEAdditionalAttendeeViewController.m
//  EventEspressoHD
//
//  Controller for displaying additional attendees associated with a group
//  registration.
//
//  Created by Michael A. Crawford on 12/7/12.
//  Copyright (c) 2012 Event Espresso. All rights reserved.
//

#import "EEAdditionalAttendeeViewController.h"
#import "EEAttendee.h"
#import "EEAttendeeCell_iPad.h"
#import "EEAttendeesRequest.h"
#import "EECheckInRequest.h"
#import "EECheckOutRequest.h"
#import "EECurrencyFormatter.h"
#import "EEDateFormatter.h"
#import "EEDateTime.h"
#import "EEPrice.h"
#import "EERegistration.h"
#import "EETransaction.h"
#import "NSUserDefaults+EventEspresso.h"
#import "SVProgressHUD.h"


@implementation EEAdditionalAttendeeViewController

- (id)initWithCoder:(NSCoder *)decoder
{
    // Allows these parameters to override display if user wishes.
    self = [super initWithCoder:decoder];
    
    if ( self )
    {
        _ticketsPurchased = NSNotFound;
        _ticketsRedeemed = NSNotFound;
    }
    
    return self;
}

#pragma mark - UIViewController Overrides

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Disable certain feature on demand.  This allows us to reuse this view
    // from the scanner interface.
    if ( self.disableCheckInCheckOut )
    {
        self.navigationItem.rightBarButtonItem = nil;
    }
    else
    {
        // Display appropriate button based on checked-in/out status.
        if ( self.registration.isCheckedIn )
        {
            [self displayCheckOutButton];
        }
        else
        {
            [self displayCheckInButton];
        }
    }
    
    if ( self.disableDoneButton )
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    // Display complete informtion for this registration
    [self reloadData];
}

#pragma mark - Target Actions

- (IBAction)checkIn:(id)sender
{
    // Let the user know we are busy.
    [SVProgressHUD showWithStatus:@"Loading"];
    
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    BOOL ignorePaymentStatus = (self.registration.transaction.status != EERegStatusComplete);
    __block EECheckInRequest* checkInRequest = [EECheckInRequest requestWithRegistrationID:self.registration.ID quantity:1 ignorePaymentStatus:ignorePaymentStatus sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        
        if ( error )
        {
            MCLog(@"Check-in request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-In Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            self.registration = checkInRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self displayCheckOutButton];
            [self reloadData];
        }
    }];
}

- (IBAction)checkOut:(id)sender
{
    // Let the user know we are busy.
    [SVProgressHUD showWithStatus:@"Loading"];
    
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    __block EECheckOutRequest* checkInRequest = [EECheckOutRequest requestWithRegistrationID:self.registration.ID quantity:1 sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [SVProgressHUD dismiss];
        
        if ( error )
        {
            MCLog(@"Check-out request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-Out Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            self.registration = checkInRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self displayCheckInButton];
            [self reloadData];
        }
    }];
}

- (IBAction)done:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private Methods

- (void)displayCheckInButton
{
    if ( EERegStatusComplete == self.registration.transaction.status )
    {
        self.checkInOutButton.title = @"Check-in";
    }
    else
    {
        self.checkInOutButton.title = @"Check-In (ignore payment)";
    }
    
    [self.checkInOutButton setAction:@selector(checkIn:)];
}

- (void)displayCheckOutButton
{
    self.checkInOutButton.title = @"Check-out";
    [self.checkInOutButton setAction:@selector(checkOut:)];
}

- (void)reloadData
{
    self.emailLabel.text            = self.registration.attendee.email;
    EEDateTime* datetime            = self.registration.datetime;
    self.eventTimeLabel.text        = datetime.eventStartTime;
    self.nameLabel.text             = self.registration.attendee.fullname;
    self.paymentStatusLabel.text    = self.registration.transaction.statusRaw;
    self.paymentTypeLabel.text      = self.registration.transaction.paymentGateway;
    self.priceLabel.text            = [[EECurrencyFormatter sharedFormatter] stringFromNumber:self.registration.finalPrice];
    self.priceOptionLabel.text      = self.registration.price.name;
    self.registrationCodeLabel.text = self.registration.code;
    self.registrationDateLabel.text = [[EEDateFormatter sharedFormatter] dateStringFromBackEndDateString:self.registration.date];
    
    // This view may be re-used by the scanner-view so we allow the overriding
    // of these last two elements in order to display an accurate summary.
    if ( NSNotFound == self.ticketsPurchased )
    {
        self.ticketsPurchasedLabel.text = @"1"; // If this value is truly constant, why bother displaying it?
    }
    else
    {
        self.ticketsPurchasedLabel.text = [NSString stringWithFormat:@"%d", self.ticketsPurchased];
    }
    
    if ( NSNotFound == self.ticketsRedeemed )
    {
        self.ticketsRedeemedLabel.text  = (self.registration.isCheckedIn ? @"1" : @"0");
    }
    else
    {
        self.ticketsRedeemedLabel.text = [NSString stringWithFormat:@"%d", self.ticketsRedeemed];
    }
}
#if 0
#pragma mark - Methods imported from AttendeeInfoViewController

- (void)configureView
{
    // If this view is displaying a group registration with multiple tickets for
    // an attendee, we need to dynamically assign the check-in/check-out controls
    // based on the number of tickets and the number remaining to be checked-in
    // or checked-out. For multiple attendees, the check-in/check-out button
    // applies only to the primary registration.  Secondary registration are
    // checked-in and out in a different view.
    //
    // For a primary with multipl tickets, there are three different scenarios:
    // 1) All tickets are checked-in; 2) all tickets are checked-out; 3) some
    // tickets are checked-in.
    
    if ( ticketsPurchased > 1 )
    {
        // 1) All tickets are checked-in;
        if ( ticketsRedeemed == ticketsPurchased )
        {
            // Display check-out button that will allow the user to pick a quantity
            // value.
            [self displayMultipleCheckOutButton];
        }
        
        // 2) All tickets are checked-out;
        else if ( 0 == ticketsRedeemed )
        {
            // Display a check-out button that will allow the user to pick a quantity
            // value.
            [self displayMultipleCheckInButton];
        }
        
        // 3) Some tickets are checked-in;
        else
        {
            // Display two buttons in a segmented control that will allow the user
            // to check-in or check-out multiple tickets.
            [self displayCheckInCheckOutButton];
        }
    }
    else
    {
        // In this case we assume we are NOT dealing with a group registration
        // so we only need to determine if the user is checked-in or checked
        // out.
        if ( ticketsPurchased == ticketsRedeemed )
        {
            [self displayCheckOutButton];
        }
        else
        {
            [self displayCheckInButton];
        }
    }
}

- (void)checkInQuantity:(NSUInteger)quantity ignorePaymentStatus:(BOOL)ignorePaymentStatus
{
    // Let the user know we are busy.
    [activityView startAnimatingInView:self.view];
    
    // Issue request to check in registered attendee.
    numTicketsPending = quantity;
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    __block EECheckInRequest* checkInRequest = [EECheckInRequest requestWithRegistrationID:self.registration.ID quantity:quantity ignorePaymentStatus:ignorePaymentStatus sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [activityView stopAnimating];
        
        if ( error )
        {
            MCLog(@"Check-in request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-In Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            ticketsRedeemed += numTicketsPending;
            self.registration = checkInRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self configureView];
            [self.attendeeInfoTableView reloadData];
        }
    }];
}

- (void)checkOutQuantity:(NSUInteger)quantity
{
    // Let the user know we are busy.
    [activityView startAnimatingInView:self.view];
    
    // Issue request to check out registered attendee.
    numTicketsPending = quantity;
    NSString* endpoint = [NSUserDefaults standardUserDefaults].endpoint;
    NSString* sessionKey = [NSUserDefaults standardUserDefaults].sessionKey;
    __block EECheckOutRequest* checkOutRequest = [EECheckOutRequest requestWithRegistrationID:self.registration.ID quantity:quantity sessionKey:sessionKey URL:[NSURL URLWithString:endpoint] completion:^(NSError *error) {
        [activityView stopAnimating];
        
        if ( error )
        {
            MCLog(@"Check-out request failed with error: %@", error);
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Check-Out Failed!" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [alert show];
        }
        else
        {
            ticketsRedeemed -= numTicketsPending;
            self.registration = checkOutRequest.returnedRegistrations[0];
            [self.delegate receivedUpdatedRegistration:self.registration];
            [self configureView];
            [self.attendeeInfoTableView reloadData];
        }
    }];
}

- (void)displayCheckInCheckOutButton
{
    if ( nil == checkInCheckOutButton )
    {
        // Create and assign control for check-in/check-out function.
        checkInCheckOutSegmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"Check-In", @"Check-Out"]];
        checkInCheckOutSegmentedControl.momentary = YES;
        checkInCheckOutSegmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        checkInCheckOutButton = [[UIBarButtonItem alloc] initWithCustomView:checkInCheckOutSegmentedControl];
        [checkInCheckOutSegmentedControl addTarget:self
                                            action:@selector(checkInCheckOutSegmentSelected:)
                                  forControlEvents:UIControlEventValueChanged];
    }
    
    self.navigationItem.rightBarButtonItem = checkInCheckOutButton;
}

- (void)displayCheckInButton
{
    if ( EERegStatusComplete == self.registration.transaction.status )
    {
        self.checkInOutButton.title = @"Check-in";
    }
    else
    {
        self.checkInOutButton.title = @"Check-In (ignore payment)";
    }
    
    [self.checkInOutButton setAction:@selector(checkIn:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
}

- (void)displayCheckOutButton
{
    self.checkInOutButton.title = @"Check-out";
    [self.checkInOutButton setAction:@selector(checkOut:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
}

- (void)displayMultipleCheckInButton
{
    if ( EERegStatusComplete == self.registration.transaction.status )
    {
        self.checkInOutButton.title = @"Check-in";
    }
    else
    {
        self.checkInOutButton.title = @"Check-In (ignore payment)";
    }
    
    [self.checkInOutButton setAction:@selector(checkInWithQuantity:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
}

- (void)displayMultipleCheckOutButton
{
    self.checkInOutButton.title = @"Check-out";
    [self.checkInOutButton setAction:@selector(checkOutWithQuantity:)];
    self.navigationItem.rightBarButtonItem = self.checkInOutButton;
}

- (void)enableControls
{
    [self.checkInOutButton setEnabled:YES];
    [checkInCheckOutButton setEnabled:YES];
    [checkInCheckOutSegmentedControl setEnabled:YES];
}
#endif
@end
